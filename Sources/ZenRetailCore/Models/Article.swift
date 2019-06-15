//
//  Article.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import PostgresNIO
import ZenPostgres


class Article: PostgresTable, Codable {
    
    public var articleId : Int = 0
    public var productId : Int = 0
    public var articleNumber : Int = 0
    public var articleBarcodes : [Barcode] = [Barcode]()
    public var articlePackaging : Packaging? = nil
    public var articleIsValid : Bool = false
    public var articleCreated : Int = Int.now()
    public var articleUpdated : Int = Int.now()

	public var _storeIds : String = "0"
    public var _quantity : Double = 0
    public var _booked : Double = 0
    public var _attributeValues: [ArticleAttributeValue] = [ArticleAttributeValue]()

    private enum CodingKeys: String, CodingKey {
        case articleId
        case productId
        case articleNumber = "number"
        case articleBarcodes = "barcodes"
        case articlePackaging = "packaging"
        case _quantity = "quantity"
        case _booked = "booked"
        case _attributeValues = "attributeValues"
    }

    override func decode(row: PostgresRow) {
        articleId = row.column("articleId")?.int ?? 0
        productId = row.column("productId")?.int ?? 0
        articleNumber = row.column("articleNumber")?.int ?? 0
        if let barcodes = row.column("articleBarcodes")?.data {
            articleBarcodes = try! JSONDecoder().decode([Barcode].self, from: barcodes)
        }
        if let packaging = row.column("articlePackaging")?.data {
            articlePackaging = try! JSONDecoder().decode(Packaging.self, from: packaging)
        }
        articleIsValid = row.column("articleIsValid")?.boolean ?? true
        articleCreated = row.column("articleCreated")?.int ?? 0
        articleUpdated = row.column("articleUpdated")?.int ?? 0
        
        do {
            _attributeValues = try ArticleAttributeValue().query(
                whereclause: "articleId = $1",
                params: [articleId],
                orderby: ["articleAttributeValueId"]
            )
            
            if _storeIds != "0" {
                var whereclause = "articleId = $1"
                if !_storeIds.isEmpty {
                    if !_storeIds.isEmpty {
                        whereclause += " AND storeId IN (\(_storeIds))"
                    }
                }
                let stocks: [Stock] = try Stock().query(
                    whereclause: whereclause,
                    params: [articleId]
                )
                _quantity = stocks.reduce(0) { $0 + $1.stockQuantity }
                _booked = stocks.reduce(0) { $0 + $1.stockBooked }
            }
        } catch {
            print(error)
        }
    }

    required init() {
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        articleId = try container.decode(Int.self, forKey: .articleId)
        productId = try container.decodeIfPresent(Int.self, forKey: .productId) ?? 0
        articleNumber = try container.decodeIfPresent(Int.self, forKey: .articleNumber) ?? 0
        articleBarcodes = try container.decodeIfPresent([Barcode].self, forKey: .articleBarcodes) ?? [Barcode]()
        articlePackaging = try? container.decodeIfPresent(Packaging.self, forKey: .articlePackaging)
        _attributeValues = try container.decodeIfPresent([ArticleAttributeValue].self, forKey: ._attributeValues) ?? [ArticleAttributeValue]()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(articleId, forKey: .articleId)
        try container.encode(articleNumber, forKey: .articleNumber)
        try container.encode(articleBarcodes, forKey: .articleBarcodes)
        try container.encodeIfPresent(articlePackaging, forKey: .articlePackaging)
        try container.encode(_quantity, forKey: ._quantity)
        try container.encode(_booked, forKey: ._booked)
        try container.encode(_attributeValues, forKey: ._attributeValues)
    }
}
