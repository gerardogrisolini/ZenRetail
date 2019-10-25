//
//  Product.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import PostgresClientKit
import ZenPostgres


class Product: PostgresTable, PostgresJson {
    
    public var productId : Int = 0
    public var brandId : Int = 0
    public var productCode : String = ""
    public var productName : String = ""
    //public var productType : String = ""
    public var productUm : String = ""
    public var productTax : Tax = Tax()
    public var productPrice : Price = Price()
    public var productSeo : Seo? = nil
    public var productDiscount : Discount? = nil
    public var productPackaging : Packaging? = nil
    public var productDescription: [Translation] = [Translation]()
    public var productMedia: [Media] = [Media]()
    public var productIsActive : Bool = false
    public var productIsValid : Bool = false
    public var productCreated : Int = Int.now()
    public var productUpdated : Int = Int.now()
    public var productAmazonUpdated : Int = 0

	public var _brand: Brand = Brand()
    public var _categories: [ProductCategory] = [ProductCategory]()
    public var _attributes: [ProductAttribute] = [ProductAttribute]()
    public var _articles: [Article] = [Article]()

    private enum CodingKeys: String, CodingKey {
        case productId
        case brandId
        case productCode
        case productName
        case productTax
        case productUm
        case productPrice = "price"
        case productDiscount = "discount"
        case productPackaging = "packaging"
        case productDescription = "translations"
        case productMedia = "medias"
        case productSeo = "seo"
        case productIsActive
        case _brand = "brand"
        case _categories = "categories"
        case _attributes = "attributes"
        case _articles = "articles"
        case productUpdated = "updatedAt"
    }

    required init() {
        super.init()
        self.tableIndexes.append("productCode")
        self.tableIndexes.append("productName")
    }
    
    override func decode(row: Row) {
        productId = (try? row.columns[0].int()) ?? 0
        brandId = (try? row.columns[1].int()) ?? 0
        productCode = (try? row.columns[2].string()) ?? ""
        productName = (try? row.columns[3].string()) ?? ""
        productUm = (try? row.columns[4].string()) ?? ""
        let decoder = JSONDecoder()
        if let tax = row.columns[5].data {
            productTax = try! decoder.decode(Tax.self, from: tax)
        }
        if let price = row.columns[6].data {
            productPrice = try! decoder.decode(Price.self, from: price)
        }
        if let seo = row.columns[7].data {
            productSeo = try! decoder.decode(Seo.self, from: seo)
        }
        if let discount = row.columns[8].data {
            productDiscount = try! decoder.decode(Discount.self, from: discount)
        }
        if let packaging = row.columns[9].data {
            productPackaging = try! decoder.decode(Packaging.self, from: packaging)
        }
        if let descriptions = row.columns[10].data {
            productDescription = try! decoder.decode([Translation].self, from: descriptions)
        }
        if let media = row.columns[11].data {
            productMedia = try! decoder.decode([Media].self, from: media)
        }
        productIsActive = (try? row.columns[12].bool()) ?? false
        productIsValid = (try? row.columns[13].bool()) ?? false
        productCreated = (try? row.columns[14].int()) ?? 0
        productUpdated = (try? row.columns[15].int()) ?? 0
        productAmazonUpdated = (try? row.columns[16].int()) ?? 0
        _ = row.columns.dropFirst(17)
        _brand.decode(row: row)
    }
    
    func rows(sql: String, barcodes: Bool, storeIds: String = "0") throws -> [Product] {
        var results = [Product]()

        let rows = try self.sqlRows(sql)
        if rows.count == 0 { return results }

        for i in 0..<rows.count {
            let row = Product(db: db!)
            row.decode(row: rows[i])
			
            try row.makeCategories();
			
			if barcodes {
				try row.makeAttributes();
				try row.makeArticles(storeIds);
			}
			
			results.append(row)
        }
        return results
    }

    required init(from decoder: Decoder) throws {
        super.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)
        productId = try container.decode(Int.self, forKey: .productId)
        productCode = try container.decode(String.self, forKey: .productCode)
        productName = try container.decode(String.self, forKey: .productName)
        productDescription = try container.decodeIfPresent([Translation].self, forKey: .productDescription) ?? [Translation]()
        //productType = try container.decode(String.self, forKey: .productType)
        productUm = try container.decode(String.self, forKey: .productUm)
        productTax = try container.decode(Tax.self, forKey: .productTax)
        productPrice = try container.decode(Price.self, forKey: .productPrice)
        productDiscount = try? container.decodeIfPresent(Discount.self, forKey: .productDiscount)
        productPackaging = try? container.decodeIfPresent(Packaging.self, forKey: .productPackaging)
        productMedia = try container.decode([Media].self, forKey: .productMedia)
        productSeo = try? container.decodeIfPresent(Seo.self, forKey: .productSeo)
        productIsActive = try container.decode(Bool.self, forKey: .productIsActive)
        _brand = try container.decodeIfPresent(Brand.self, forKey: ._brand) ?? Brand()
        brandId = try container.decodeIfPresent(Int.self, forKey: .brandId) ?? _brand.brandId

        _categories = try container.decodeIfPresent([ProductCategory].self, forKey: ._categories) ?? [ProductCategory]()
        _attributes = try container.decodeIfPresent([ProductAttribute].self, forKey: ._attributes) ?? [ProductAttribute]()
        _articles = try container.decodeIfPresent([Article].self, forKey: ._articles) ?? [Article]()
   }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(productId, forKey: .productId)
        try container.encode(productCode, forKey: .productCode)
        try container.encode(productName, forKey: .productName)
        try container.encode(productDescription, forKey: .productDescription)
        //try container.encode(productType, forKey: .productType)
        try container.encode(productUm, forKey: .productUm)
        try container.encode(productTax, forKey: .productTax)
        try container.encode(productPrice, forKey: .productPrice)
        try container.encodeIfPresent(productDiscount, forKey: .productDiscount)
        try container.encodeIfPresent(productPackaging, forKey: .productPackaging)
        try container.encode(productMedia, forKey: .productMedia)
        try container.encodeIfPresent(productSeo, forKey: .productSeo)
        try container.encode(productIsActive, forKey: .productIsActive)
        try container.encode(_brand, forKey: ._brand)
        try container.encode(_categories, forKey: ._categories)
        try container.encode(_attributes, forKey: ._attributes)
        try container.encode(_articles, forKey: ._articles)
        try container.encode(productUpdated, forKey: .productUpdated)
    }

	func makeCategories() throws {
		let categoryJoin = DataSourceJoin(
            table: "Category",
            onCondition: "ProductCategory.categoryId = Category.categoryId"
        )
		
        self._categories = try ProductCategory(db: db!).query(
			whereclause: "ProductCategory.productId = $1",
			params: [self.productId],
			orderby: ["Category.categoryId"],
			joins: [categoryJoin]
		)
	}

    func addDefaultAttributes() throws {
        let productAttribute = ProductAttribute()
        productAttribute.productId = self.productId
        let attribute = Attribute()
        attribute.attributeName = "None"
        productAttribute._attribute = attribute
        let productAttributeValue = ProductAttributeValue()
        let attributeValue = AttributeValue()
        attributeValue.attributeValueName = "None"
        productAttributeValue._attributeValue = attributeValue
        productAttribute._attributeValues = [productAttributeValue]
        self._attributes.append(productAttribute)
    }
    
    func makeAttributes() throws {
		let attributeJoin = DataSourceJoin(
            table: "Attribute",
            onCondition: "ProductAttribute.attributeId = Attribute.attributeId"
        )
		
        let productAttribute = ProductAttribute(db: db!)
		self._attributes = try productAttribute.query(
			whereclause: "ProductAttribute.productId = $1",
			params: [self.productId],
			orderby: ["ProductAttribute.productAttributeId"],
			joins: [attributeJoin]
		)
	}

    func makeArticles(_ storeIds: String = "0") throws {
		let article = Article(db: db!)
        article._storeIds = storeIds
		self._articles = try article.query(
			whereclause: "productId = $1",
			params: [self.productId],
			orderby: ["articleId"]
		)
	}

	func makeArticle(barcode: String, rows: [Row]) throws {
        let article = Article(db: db!)
        article.decode(row: rows[0])
        article._attributeValues = rows.map({ row -> ArticleAttributeValue in
            let a = ArticleAttributeValue()
            a.decode(row: row)
            return a
        })
        self._articles = [article]
	}

    func get(barcode: String) throws {
        let brandJoin = DataSourceJoin(
            table: "Brand",
            onCondition: "Product.brandId = Brand.brandId",
            direction: .INNER
        )
        let articleJoin = DataSourceJoin(
            table: "Article",
            onCondition: "Product.productId = Article.productId",
            direction: .INNER
        )
        let articleAttributeJoin = DataSourceJoin(
            table: "ArticleAttributeValue",
            onCondition: "ArticleAttributeValue.articleId = Article.articleId",
            direction: .LEFT
        )

        let param = """
'[{"barcode": "\(barcode)"}]'::jsonb
"""
        let sql = querySQL(whereclause: "Article.articleBarcodes @> $1",
                           params: [param],
                           orderby: ["ArticleAttributeValue.articleAttributeValueId"],
                           joins: [brandJoin, articleJoin, articleAttributeJoin])
        let rows = try self.sqlRows(sql)
        if rows.count == 0 { return }
        
        self.decode(row: rows[0])
        try self.makeCategories()
        try self.makeAttributes()
        try self.makeArticle(barcode: barcode, rows: rows)
    }
}
