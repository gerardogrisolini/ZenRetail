//
//  ProductRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import PostgresNIO
import ZenPostgres
import ZenNIO
import SwiftGD

struct ProductRepository : ProductProtocol {

    func getTaxes() -> [Tax] {
        var taxes = [Tax]()
        taxes.append(Tax(name: "Standard rate", value: 22))
        taxes.append(Tax(name: "Reduced rate", value: 10))
        taxes.append(Tax(name: "Zero rate", value: 0))
        return taxes
    }
    
    func getProductTypes() -> [ItemValue] {
        var types = [ItemValue]()
        types.append(ItemValue(value: "Simple"))
        types.append(ItemValue(value: "Variant"))
        //types.append(ItemValue(value: "Grouped"))
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
		
	func getAll(date: Int) -> EventLoopFuture<[Product]> {
        let obj = Product()
        let sql = obj.querySQL(
			whereclause: "Product.productUpdated > $1", params: [date],
			orderby: ["Product.productId"],
			joins: defaultJoins()
		)

        return obj.rowsAsync(sql: sql, barcodes: date > 0)
    }
	
    func getAmazonChanges() -> EventLoopFuture<[Product]> {
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
        
        return obj.rowsAsync(sql: sql, barcodes: true, storeIds: "")
    }
    
	func get(id: Int) -> EventLoopFuture<Product> {
        let product = Product()
        return product.getAsync(id).map { () -> Product in
            return product
        }
	}

    func get(barcode: String) -> EventLoopFuture<Product> {
        let product = Product()
        return product.getAsync(barcode: barcode).map { () -> Product in
            return product
        }
    }
    
    func reset(id: Int) -> EventLoopFuture<Int> {
        return Product().updateAsync(cols: ["productAmazonUpdated"], params: [1], id: "productId", value: id)
    }
    
    func add(item: Product) -> EventLoopFuture<Int> {
        let promise: EventLoopPromise<Int> = ZenRetail.zenNIO.eventLoopGroup.next().makePromise()

        let q = ZenPostgres.pool.connectAsync()
        q.whenSuccess { connection in
            defer { connection.disconnect() }

            item.connection = connection
            
            /// Brand
            let brand = Brand(connection: connection)
            brand.getAsync("brandName", item._brand.brandName).whenComplete { _ in
                if brand.brandId == 0 {
                    brand.brandName = item._brand.brandName
                    brand.brandDescription = item._brand.brandDescription
                    brand.brandMedia = item._brand.brandMedia
                    brand.brandSeo = item._brand.brandSeo
                    brand.brandCreated = Int.now()
                    brand.brandUpdated = Int.now()
                    brand.saveAsync().whenComplete { result in
                        switch result {
                        case .success(let id):
                            item.brandId = id as! Int
                        case .failure(let err):
                            promise.fail(err)
                            return
                        }
                    }
                } else {
                    item.brandId = brand.brandId
                }
            }

            /// Categories
            for c in item._categories.sorted(by: { $0._category.categoryIsPrimary.hashValue < $1._category.categoryIsPrimary.hashValue }) {
                var category = Category(connection: connection)
                let query: EventLoopFuture<[Category]> = category.queryAsync(
                    whereclause: "categoryName = $1", params: [c._category.categoryName],
                    cursor: Cursor(limit: 1, offset: 0)
                )
                query.whenSuccess { categories in
                    if categories.count == 1 {
                        category = categories.first!
                        c.categoryId = category.categoryId
                    } else {
                        category.categoryName = c._category.categoryName
                        category.categoryIsPrimary = c._category.categoryIsPrimary
                        category.categoryDescription = c._category.categoryDescription
                        category.categoryMedia = c._category.categoryMedia
                        category.categorySeo = c._category.categorySeo
                        category.categoryCreated = Int.now()
                        category.categoryUpdated = Int.now()
                        category.saveAsync().whenComplete { result in
                            switch result {
                            case .success(let id):
                                category.categoryId = id as! Int
                            case .failure(let err):
                                promise.fail(err)
                                return
                            }
                        }
                    }
                }
                query.whenFailure { err in
                    promise.fail(err)
                }
            }
            
            /// Medias
            for var m in item.productMedia {
                if m.name.hasPrefix("http") || m.name.hasPrefix("ftp") {
                    try? self.download(media: &m)
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
            return item.saveAsync().whenComplete { result in
                switch result {
                case .success(let id):
                    item.productId = id as! Int
                    
                    /// ProductCategories
                    let count = item._categories.count - 1
                    for (i, c) in item._categories.enumerated() {
                        let productCategory = ProductCategory(connection: connection)
                        productCategory.productId = item.productId
                        productCategory.categoryId = c.categoryId
                        productCategory.saveAsync().whenComplete { result in
                            switch result {
                            case .success(let id):
                                c.productCategoryId = id as! Int
                                if i == count {
                                    promise.succeed(item.productId)
                                }
                            case .failure(let err):
                                promise.fail(err)
                                return
                            }
                        }
                    }
                case .failure(let err):
                    promise.fail(err)
                }
            }
        }
        q.whenFailure { err in
            promise.fail(err)
        }

        return promise.futureResult
    }
    
    func update(id: Int, item: Product) -> EventLoopFuture<Bool> {
        let promise: EventLoopPromise<Bool> = ZenRetail.zenNIO.eventLoopGroup.next().makePromise()

        let q = ZenPostgres.pool.connectAsync()
        q.whenSuccess { connection in
            defer { connection.disconnect() }

            let current = Product(connection: connection)
            let get = current.getAsync(id)
            get.whenSuccess { _ in
                current.connection = connection
                current.productCode = item.productCode
                current.productName = item.productName
                //current.productType = item.productType
                current.productUm = item.productUm
                current.productPrice = item.productPrice
                current.productDiscount = item.productDiscount
                current.productPackaging = item.productPackaging
                current.productIsActive = item.productIsActive
                current.brandId = item.brandId

                /// Categories
                for c in item._categories.sorted(by: { $0._category.categoryIsPrimary.hashValue < $1._category.categoryIsPrimary.hashValue }) {
                    var category = Category(connection: connection)
                    let query: EventLoopFuture<[Category]> = category.queryAsync(
                        whereclause: "categoryName = $1", params: [c._category.categoryName],
                        cursor: Cursor(limit: 1, offset: 0)
                    )
                    query.whenSuccess { categories in
                        if categories.count == 1 {
                            category = categories.first!
                            c.categoryId = category.categoryId
                        } else {
                            category.categoryName = c._category.categoryName
                            category.categoryIsPrimary = c._category.categoryIsPrimary
                            category.categoryDescription = c._category.categoryDescription
                            category.categoryMedia = c._category.categoryMedia
                            category.categorySeo = c._category.categorySeo
                            category.categoryCreated = Int.now()
                            category.categoryUpdated = Int.now()
                            category.saveAsync().whenComplete { result in
                                switch result {
                                case .success(let id):
                                    category.categoryId = id as! Int
                                case .failure(let err):
                                    promise.fail(err)
                                    return
                                }
                            }
                        }
                    }
                    query.whenFailure { err in
                        promise.fail(err)
                    }
                }
                
                /// ProductCategories
                for c in current._categories {
                    c.connection = connection
                    c.deleteAsync().whenComplete { _ in }
                }
                for c in item._categories {
                    c.productCategoryId = 0
                    c.productId = id
                    c.connection = connection
                    c.saveAsync().whenComplete { result in
                        switch result {
                        case .success(let id):
                            c.productCategoryId = id as! Int
                        case .failure(let err):
                            promise.fail(err)
                            return
                        }
                    }
                }
                
                /// Articles
                if let itemArticle = item._articles.first(where: { $0._attributeValues.count == 0 }) {
                    if let itemBarcode = itemArticle.articleBarcodes.first(where: { $0.tags.count == 0 }) {
                        if let currentArticle = current._articles.first(where: { $0._attributeValues.count == 0 }) {
                            let currentBarcode = currentArticle.articleBarcodes.first(where: { $0.tags.count == 0 })!
                            currentBarcode.barcode = itemBarcode.barcode
                            currentArticle.connection = connection
                            currentArticle.saveAsync().whenComplete { result in
                                switch result {
                                case .success(let id):
                                    currentArticle.articleId = id as! Int
                                case .failure(let err):
                                    promise.fail(err)
                                    return
                                }
                            }
                        } else {
                            itemArticle.articleIsValid = true
                            itemArticle.articleId = 0
                            itemArticle.productId = id
                            itemArticle.articleUpdated = Int.now()
                            itemArticle.connection = connection
                            itemArticle.saveAsync().whenComplete { result in
                                switch result {
                                case .success(let id):
                                    itemArticle.articleId = id as! Int
                                case .failure(let err):
                                    promise.fail(err)
                                    return
                                }
                            }
                        }
                    }
                }
                
//                if item.productType == "Grouped" {
//                    for a in current._articles.filter({ $0._attributeValues.count > 0 }) {
//                        try a.delete()
//                    }
//                    for a in item._articles.filter({ $0._attributeValues.count > 0 }) {
//                        a.articleId = 0
//                        a.productId = id
//                        try a.save {
//                            id in a.articleId = id as! Int
//                        }
//                    }
//                }
                
                /// Medias
                for var m in item.productMedia {
                    if m.name.hasPrefix("http") || m.name.hasPrefix("ftp") {
                        try? self.download(media: &m)
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
                current.saveAsync().whenComplete { result in
                    switch result {
                    case .success(let id):
                        item.productId = id as! Int
                        promise.succeed(item.productId > 0)
                    case .failure(let err):
                        promise.fail(err)
                    }
                }
            }
            get.whenFailure { err in
                promise.fail(err)
            }
        }
        q.whenFailure { err in
            promise.fail(err)
        }

        return promise.futureResult
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
        big.fileType = MediaType.media.rawValue
        big.fileContentType = media.contentType
        big.setData(data: data)
        try big.save()
        
        if let thumb = try Image(data: data).resizedTo(width: 380) {
//            let url = URL(fileURLWithPath: "\(ZenNIO.htdocsPath)/thumb/\(media.name)")
//            if !thumb.write(to: url, quality: 75, allowOverwrite: true) {
//                throw HttpError.systemError(0, "file thumb not saved")
//            }
            let small = File()
            small.fileName = media.name
            small.fileType = MediaType.thumb.rawValue
            small.fileContentType = media.contentType
            small.setData(data: try thumb.export())
            try small.save()
        }
    }
    
    func sync(item: Product) throws -> Product {
        let connection = try ZenPostgres.pool.connect()
        defer { connection.disconnect() }

        item.connection = connection
        
        /// Fix empty attribute
        if item._attributes.count == 0 {
            try item.addDefaultAttributes()
        }

        /// Attributes
        for a in item._attributes {
            let attribute = Attribute(connection: connection)
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
                let attributeValue = AttributeValue(connection: connection)
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
        let attributes: [ProductAttribute] = try ProductAttribute(connection: connection).query(
            whereclause: "productId = $1",
            params: [item.productId]
        )
        for a in attributes {
            let attributeValue = ProductAttributeValue(connection: connection)
            a._attributeValues = try attributeValue.query(
                whereclause: "productAttributeId = $1",
                params: [a.productAttributeId]
            )
        }

        /// ProductAttributes
        for a in item._attributes {
            let productAttribute = ProductAttribute(connection: connection)
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
                let productAttributeValue = ProductAttributeValue(connection: connection)
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
                a.connection = connection
                try a.delete()
                continue
            }
            for v in a._attributeValues {
                v.connection = connection
                try v.delete()
            }
        }
        
        return item
    }
    
    func syncImport(item: Product) throws -> Result {
        let connection = try ZenPostgres.pool.connect()
        defer { connection.disconnect() }

        let result = try (ZenIoC.shared.resolve() as ArticleProtocol).build(productId: item.productId)
        
        /// Sync barcodes
        for a in item._articles.filter({ $0._attributeValues.count > 0 }) {
            let values = a._attributeValues.map({ a in a._attributeValue.attributeValueName }).joined(separator: "', '")
            let article = Article(connection: connection)
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
        let publication = Publication(connection: connection)
        publication.productId = item.productId
        publication.publicationStartAt = "2019-01-01".DateToInt()
        publication.publicationFinishAt = "2030-12-31".DateToInt()
        try publication.save {
            id in publication.publicationId = id as! Int
        }
        
        return result
    }

    func delete(id: Int) throws {
        let connection = try ZenPostgres.pool.connect()
        defer { connection.disconnect() }

        let item = Product(connection: connection)
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
