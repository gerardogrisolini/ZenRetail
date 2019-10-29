//
//  ProductRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import PostgresClientKit
import ZenPostgres
import ZenNIO
import SwiftGD

struct ProductRepository : ProductProtocol {

    func getTaxes() throws -> [Tax] {
        var taxes = [Tax]()
        taxes.append(Tax(name: "Standard rate", value: 22))
        taxes.append(Tax(name: "Reduced rate", value: 10))
        taxes.append(Tax(name: "Zero rate", value: 0))
        return taxes
    }
    
    func getProductTypes() throws -> [ItemValue] {
        var types = [ItemValue]()
        types.append(ItemValue(value: "Simple"))
        types.append(ItemValue(value: "Variant"))
        types.append(ItemValue(value: "Grouped"))
        return types
    }

    internal func defaultJoins() -> [DataSourceJoin] {
        return [
            DataSourceJoin(
                table: "Brand",
                onCondition: "Product.brandId = Brand.brandId",
                direction: .INNER
            ),
            DataSourceJoin(
                table: "ProductCategory",
                onCondition: "Product.productId = ProductCategory.productId",
                direction: .LEFT
            ),
            DataSourceJoin(
                table: "Category",
                onCondition: "ProductCategory.categoryId = Category.categoryId",
                direction: .INNER
            )
        ]
	}
		
	func getAll(date: Int) throws -> [Product] {
        let obj = Product()
        let sql = obj.querySQL(
			whereclause: "productUpdated > $1", params: [date],
			orderby: ["Product.productId"],
			joins: defaultJoins()
		)

        return try obj.rows(sql: sql, barcodes: date > 0)
    }
	
    func getAmazonChanges() throws -> [Product] {
        let publication = DataSourceJoin(
            table: "Publication",
            onCondition: "Product.productId = Publication.productId",
            direction: .INNER
        )
        var joins = defaultJoins()
        joins.append(publication)
        
        let obj = Product()
        let sql = obj.querySQL(
            whereclause: "Product.productUpdated > Product.productAmazonUpdated AND Product.productAmazonUpdated > $1 AND Publication.publicationStartAt <= $2 AND Publication.publicationFinishAt >= $2",
            params: [0, Int.now()],
            orderby: ["Product.productUpdated"],
            joins: joins
        )
        
        return try obj.rows(sql: sql, barcodes: true, storeIds: "")
    }
    
	func get(id: Int) throws -> Product {
        let db = try ZenPostgres.shared.connect()
        defer { db.disconnect() }
        
        let item = Product(db: db)
        let sql = item.querySQL(
            whereclause: "Product.productId = $1",
            params: [String(id)],
            cursor: CursorConfig(limit: 1, offset: 0),
            joins: defaultJoins()
        )
 
        let rows = try item.sqlRows(sql)
        if rows.count == 0 { throw ZenError.recordNotFound }

        let groups = rows.groupBy { row -> Int in
            try! row.columns[0].int()
        }
        
        for group in groups {
            item.decode(row: group.value.first!)
            
            for var cat in group.value {
                let productCategory = ProductCategory()
                cat.columns = Array(cat.columns.dropFirst(24))
                productCategory.decode(row: cat)
                item._categories.append(productCategory)
            }
        }

        try item.makeAttributes()
		try item.makeArticles()
		
		return item
	}

    func get(barcode: String) throws -> Product {
        let db = try ZenPostgres.shared.connect()
        defer { db.disconnect() }

        let item = Product(db: db)
        try item.get(barcode: barcode)
        
        return item
    }
    
    func reset(id: Int) throws {
        let item = Product()
        _ = try item.update(cols: ["productAmazonUpdated"], params: [1], id: "productId", value: id)
    }
    
    func add(item: Product) throws {
        let db = try ZenPostgres.shared.connect()
        defer { db.disconnect() }
        
        item.db = db
        
        /// Brand
        let brand = Brand(db: db)
        try? brand.get("brandName", item._brand.brandName)
        if brand.brandId == 0 {
            brand.brandName = item._brand.brandName
            brand.brandDescription = item._brand.brandDescription
            brand.brandMedia = item._brand.brandMedia
            brand.brandSeo = item._brand.brandSeo
            brand.brandCreated = Int.now()
            brand.brandUpdated = Int.now()
            try brand.save {
                id in brand.brandId = id as! Int
            }
        }
        item.brandId = brand.brandId

        /// Categories
        for c in item._categories.sorted(by: { $0._category.categoryIsPrimary.hashValue < $1._category.categoryIsPrimary.hashValue }) {
            var category = Category(db: db)
            let categories: [Category] = try category.query(
                whereclause: "categoryName = $1", params: [c._category.categoryName],
                cursor: CursorConfig(limit: 1, offset: 0)
            )
            if categories.count == 1 {
                category = categories.first!
            } else {
                category.categoryName = c._category.categoryName
                category.categoryIsPrimary = c._category.categoryIsPrimary
                category.categoryDescription = c._category.categoryDescription
                category.categoryMedia = c._category.categoryMedia
                category.categorySeo = c._category.categorySeo
                category.categoryCreated = Int.now()
                category.categoryUpdated = Int.now()
                try category.save {
                    id in category.categoryId = id as! Int
                }
            }
            c.categoryId = category.categoryId
        }
        
        /// Medias
        for var m in item.productMedia {
            if m.name.hasPrefix("http") || m.name.hasPrefix("ftp") {
                try download(media: &m)
            }
        }
        
        /// Seo
        if let seo = item.productSeo {
            if (seo.permalink.isEmpty) {
                seo.permalink = item.productName.permalink()
            }
            seo.description = seo.description.filter({ !$0.value.isEmpty })
        }
        
        /// Discount
        item.productDiscount?.makeDiscount(sellingPrice: item.productPrice.selling)

        /// Product
        item.productDescription = item.productDescription.filter({ !$0.value.isEmpty })
        item.productCreated = Int.now()
        item.productUpdated = Int.now()
        try item.save {
            id in item.productId = id as! Int
        }
        
        /// ProductCategories
        for c in item._categories {
            let productCategory = ProductCategory(db: db)
            productCategory.productId = item.productId
            productCategory.categoryId = c.categoryId
            try productCategory.save {
                id in productCategory.productCategoryId = id as! Int
            }
        }
        
//        /// Articles
//        let articles = item.productType == "Variant"
//            ? item._articles.filter({ $0._attributeValues.count == 0 })
//            : item._articles
//        for article in articles {
//            article.productId = item.productId
//            article.articleIsValid = true
//            article.articleCreated = Int.now()
//            article.articleUpdated = Int.now()
//            try article.save {
//                id in article.articleId = id as! Int
//            }
//        }
    }
    
    func update(id: Int, item: Product) throws {
        let current = try get(id: id)

        let db = try ZenPostgres.shared.connect()
        defer { db.disconnect() }

        current.db = db
        current.productCode = item.productCode
        current.productName = item.productName
        //current.productType = item.productType
        current.productUm = item.productUm
        current.productPrice = item.productPrice
        current.productDiscount = item.productDiscount
        current.productPackaging = item.productPackaging
        current.productIsActive = item.productIsActive

        /// Brand
        let brand = Brand(db: db)
        try? brand.get("brandName", item._brand.brandName)
        if brand.brandId == 0 {
            brand.brandName = item._brand.brandName
            brand.brandDescription = item._brand.brandDescription
            brand.brandMedia = item._brand.brandMedia
            brand.brandSeo = item._brand.brandSeo
            brand.brandCreated = Int.now()
            brand.brandUpdated = Int.now()
            try brand.save {
                id in brand.brandId = id as! Int
            }
        }
        item.brandId = brand.brandId
        current.brandId = item.brandId
        
        /// Categories
        for c in item._categories.sorted(by: { $0._category.categoryIsPrimary.hashValue < $1._category.categoryIsPrimary.hashValue }
            ) {
            let category = Category(db: db)
            try? category.get("categoryName", c._category.categoryName)
            if category.categoryId == 0 {
                category.categoryName = c._category.categoryName
                category.categoryIsPrimary = c._category.categoryIsPrimary
                category.categoryDescription = c._category.categoryDescription
                category.categoryMedia = c._category.categoryMedia
                category.categorySeo = c._category.categorySeo
                category.categoryCreated = Int.now()
                category.categoryUpdated = Int.now()
                try category.save {
                    id in category.categoryId = id as! Int
                }
            }
            c.categoryId = category.categoryId
        }
        
        /// ProductCategories
        for c in current._categories {
            c.db = db
            try c.delete()
        }
        for c in item._categories {
            c.productCategoryId = 0
            c.productId = id
            c.db = db
            try c.save {
                id in c.productCategoryId = id as! Int
            }
        }
        
        /// Articles
        if let itemArticle = item._articles.first(where: { $0._attributeValues.count == 0 }) {
            if let itemBarcode = itemArticle.articleBarcodes.first(where: { $0.tags.count == 0 }) {
                if let currentArticle = current._articles.first(where: { $0._attributeValues.count == 0 }) {
                    let currentBarcode = currentArticle.articleBarcodes.first(where: { $0.tags.count == 0 })!
                    currentBarcode.barcode = itemBarcode.barcode
                    currentArticle.db = db
                    try currentArticle.save()
                } else {
                    itemArticle.articleIsValid = true
                    itemArticle.articleId = 0
                    itemArticle.productId = id
                    itemArticle.articleUpdated = Int.now()
                    itemArticle.db = db
                    try itemArticle.save {
                        id in itemArticle.articleId = id as! Int
                    }
                }
            }
        }
        
//        if item.productType == "Grouped" {
//            for a in current._articles.filter({ $0._attributeValues.count > 0 }) {
//                try a.delete()
//            }
//            for a in item._articles.filter({ $0._attributeValues.count > 0 }) {
//                a.articleId = 0
//                a.productId = id
//                try a.save {
//                    id in a.articleId = id as! Int
//                }
//            }
//        }
        
        /// Medias
        for var m in item.productMedia {
            if m.name.hasPrefix("http") || m.name.hasPrefix("ftp") {
                try download(media: &m)
            }
        }
        current.productMedia = item.productMedia

        /// Seo
        if let seo = item.productSeo {
            if (seo.permalink.isEmpty) {
                seo.permalink = item.productName.permalink()
            }
            seo.description = seo.description.filter({ !$0.value.isEmpty })
            current.productSeo = seo
        }
        
        /// Discount
        item.productDiscount?.makeDiscount(sellingPrice: item.productPrice.selling)
        current.productDiscount = item.productDiscount;
        
        /// Product
        current.productDescription = item.productDescription.filter({ !$0.value.isEmpty })
        item.productUpdated = Int.now()
        current.productUpdated = item.productUpdated
        try current.save()
    }

    fileprivate func download(media: inout Media) throws {
        guard let url = URL(string: media.name) else {
            throw ZenError.recordNotFound
        }
        let data = try Data(contentsOf: url)
        
        media.contentType = media.name.contentType
        media.name = media.name.uniqueName()
        
        let big = File()
        big.fileName = media.name
        //big.fileType = MediaType.media.rawValue
        big.fileContentType = media.contentType
        big.setData(data: data)
        try big.save()
        
        if let thumb = try Image(data: data).resizedTo(width: 380) {
            let url = URL(fileURLWithPath: "\(ZenNIO.htdocsPath)/thumb/\(media.name)")
            if !thumb.write(to: url, quality: 75, allowOverwrite: true) {
                throw HttpError.systemError(0, "file thumb not saved")
            }
//            let small = File()
//            small.fileName = media.name
//            small.fileType = MediaType.thumb.rawValue
//            small.fileContentType = media.contentType
//            small.setData(data: try thumb.export())
//            try small.save()
        }
    }
    
    func sync(item: Product) throws -> Product {
        let db = try ZenPostgres.shared.connect()
        defer { db.disconnect() }

        item.db = db
        
        /// Fix empty attribute
        if item._attributes.count == 0 {
            try item.addDefaultAttributes()
        }

        /// Attributes
        for a in item._attributes {
            let attribute = Attribute(db: db)
            try? attribute.get("attributeName", a._attribute.attributeName)
            if attribute.attributeId == 0 {
                attribute.attributeName = a._attribute.attributeName
                attribute.attributeTranslates = a._attribute.attributeTranslates
                attribute.attributeCreated = Int.now()
                attribute.attributeUpdated = Int.now()
                try attribute.save {
                    id in attribute.attributeId = id as! Int
                }
            }
            a.attributeId = attribute.attributeId

            /// AttributeValues
            for v in a._attributeValues.sorted(by: { $0._attributeValue.attributeValueCode < $1._attributeValue.attributeValueCode }) {
                let attributeValue = AttributeValue(db: db)
                try? attributeValue.get("attributeId\" = \(a.attributeId) AND \"attributeValueName", v._attributeValue.attributeValueName)
                if attributeValue.attributeValueId == 0 {
                    attributeValue.attributeId = a.attributeId
                    attributeValue.attributeValueCode = v._attributeValue.attributeValueCode
                    attributeValue.attributeValueName = v._attributeValue.attributeValueName
                    attributeValue.attributeValueMedia = v._attributeValue.attributeValueMedia
                    attributeValue.attributeValueTranslates = v._attributeValue.attributeValueTranslates
                    attributeValue.attributeValueCreated = Int.now()
                    attributeValue.attributeValueUpdated = Int.now()
                    try attributeValue.save {
                        id in attributeValue.attributeValueId = id as! Int
                    }
                }
                v.attributeValueId = attributeValue.attributeValueId
            }
        }

        /// Get current attributes and values
        let attributes: [ProductAttribute] = try ProductAttribute(db: db).query(
            whereclause: "productId = $1",
            params: [item.productId]
        )
        for a in attributes {
            let attributeValue = ProductAttributeValue(db: db)
            a._attributeValues = try attributeValue.query(
                whereclause: "productAttributeId = $1",
                params: [a.productAttributeId]
            )
        }

        /// ProductAttributes
        for a in item._attributes {
            let productAttribute = ProductAttribute(db: db)
            try? productAttribute.get("productId\" = \(item.productId) AND \"attributeId", a.attributeId)
            if productAttribute.productAttributeId == 0 {
                productAttribute.productId = item.productId
                productAttribute.attributeId = a.attributeId
                try productAttribute.save {
                    id in productAttribute.productAttributeId = id as! Int
                 }
            }
            a.productAttributeId = productAttribute.productAttributeId
            
            let current = attributes.first(where: { $0.attributeId == a.attributeId })
            current?.productId = 0
            
            /// ProductAttributeValues
            for v in a._attributeValues {
                let productAttributeValue = ProductAttributeValue(db: db)
                try? productAttributeValue.get("productAttributeId\" = \(a.productAttributeId) AND \"attributeValueId", v.attributeValueId)
                if productAttributeValue.productAttributeValueId == 0 {
                    productAttributeValue.productAttributeId = a.productAttributeId
                    productAttributeValue.attributeValueId = v.attributeValueId
                    try productAttributeValue.save {
                        id in productAttributeValue.productAttributeValueId = id as! Int
                    }
                }
                v.productAttributeValueId = productAttributeValue.productAttributeValueId

                if let index = current?._attributeValues.firstIndex(of: productAttributeValue) {
                    current?._attributeValues.remove(at: index)
                }
            }
        }
        
        /// Clean attributes
        for a in attributes {
            if a.productId > 0 {
                a.db = db
                try a.delete()
                continue
            }
            for v in a._attributeValues {
                v.db = db
                try v.delete()
            }
        }
        
        return item
    }
    
    func syncImport(item: Product) throws -> Result {
        let db = try ZenPostgres.shared.connect()
        defer { db.disconnect() }

        let result = try (ZenIoC.shared.resolve() as ArticleProtocol).build(productId: item.productId)
        
        /// Sync barcodes
        for a in item._articles.filter({ $0._attributeValues.count > 0 }) {
            let values = a._attributeValues.map({ a in a._attributeValue.attributeValueName }).joined(separator: "', '")
            let article = Article(db: db)
            let current = try article.sqlRows("""
SELECT a.*
FROM "Article" as a
LEFT JOIN "ArticleAttributeValue" as b ON a."articleId" = b."articleId"
LEFT JOIN "AttributeValue" as c ON b."attributeValueId" = c."attributeValueId"
WHERE c."attributeValueName" IN ('\(values)') AND a."productId" = \(item.productId)
GROUP BY a."articleId" HAVING count(b."attributeValueId") = \(item._attributes.count)
""")
            if current.count > 0 {
                article.decode(row: current[0])
                article.articleBarcodes = a.articleBarcodes
                try article.save()
            }
        }
        
        /// Publication
        let publication = Publication(db: db)
        publication.productId = item.productId
        publication.publicationStartAt = "2019-01-01".DateToInt()
        publication.publicationFinishAt = "2030-12-31".DateToInt()
        try publication.save {
            id in publication.publicationId = id as! Int
        }
        
        return result
    }

    func delete(id: Int) throws {
        let db = try ZenPostgres.shared.connect()
        defer { db.disconnect() }

        let item = Product(db: db)
        item.productId = id
        try item.delete()

        let productId = String(id)
        _ = try item.sqlRows("DELETE FROM \"ProductCategory\" WHERE \"productId\" = \(productId)")
        _ = try item.sqlRows("""
DELETE FROM "ProductAttributeValue"
WHERE "productAttributeId" IN
(
    SELECT "productAttributeId"
    FROM   "ProductAttribute"
    WHERE  "productId" = \(productId)
)
""")
        _ = try item.sqlRows("DELETE FROM \"ProductAttribute\" WHERE \"productId\" = \(productId)")
        _ = try item.sqlRows("""
DELETE FROM "ArticleAttributeValue"
WHERE "articleId" IN
(
    SELECT "articleId"
    FROM   "Article"
    WHERE  "productId" = \(productId)
)
""")
        _ = try item.sqlRows("""
DELETE FROM "Stock"
WHERE "articleId" IN
(
    SELECT "articleId"
    FROM   "Article"
    WHERE  "productId" = \(productId)
)
""")
        _ = try item.sqlRows("DELETE FROM \"Article\" WHERE \"productId\" = \(productId)")
        _ = try item.sqlRows("DELETE FROM \"Publication\" WHERE \"productId\" = \(productId)")
    }

    /*
	func addAttribute(item: ProductAttribute) throws {
        try item.save {
            id in item.productAttributeId = id as! Int
        }
        try setValid(productId: item.productId, valid: false)
    }
    
    func removeAttribute(item: ProductAttribute) throws {
		try item.query(whereclause: "productId = $1 AND attributeId = $2",
		               params: [item.productId, item.attributeId],
		               cursor: Cursor(limit: 1, offset: 0))
        try item.delete()
        try setValid(productId: item.productId, valid: false)
    }
    
    func addAttributeValue(item: ProductAttributeValue) throws {
        try item.save {
            id in item.productAttributeValueId = id as! Int
        }
        try setValid(productAttributeId: item.productAttributeId, valid: false)
    }
    
    func removeAttributeValue(item: ProductAttributeValue) throws {
		try item.query(whereclause: "productAttributeId = $1 AND attributeValueId = $2",
		               params: [item.productAttributeId, item.attributeValueId],
		               cursor: Cursor(limit: 1, offset: 0))
        try item.delete()
        try setValid(productAttributeId: item.productAttributeId, valid: false)
    }
 
    internal func setValid(productId: Int, valid: Bool) throws {
        let product = try get(id: productId)
        defer { product.db!.disconnect() }
        if product.productIsValid != valid {
            product.productIsValid = valid
            try update(id: productId, item: product)
        }
    }
    
    internal func setValid(productAttributeId: Int, valid: Bool) throws {
        let productAttribute = ProductAttribute()
        try productAttribute.get(productAttributeId)
        try setValid(productId: productAttribute.productId, valid: valid)
    }
     */
}
