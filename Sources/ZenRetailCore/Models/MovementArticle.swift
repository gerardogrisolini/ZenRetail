//
//  MovementArticle.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

import Foundation
import PostgresNIO
import ZenPostgres


class MovementArticle: PostgresTable, Codable {
    
    public var movementArticleId : Int = 0
    public var movementId : Int = 0
    public var movementArticleBarcode : String = ""
    public var movementArticleProduct : Product = Product()
    public var movementArticleQuantity : Double = 0
    public var movementArticleDelivered : Double = 0
	public var movementArticlePrice : Double = 0
	public var movementArticleUpdated : Int = Int.now()
    
    public var _movementArticleAmount: Double {
        return (movementArticleQuantity * movementArticlePrice).roundCurrency()
    }

    private enum CodingKeys: String, CodingKey {
        case movementArticleId
        case movementId
        case movementArticleBarcode
        case movementArticleProduct
        case movementArticleQuantity
        case movementArticleDelivered
        case movementArticlePrice
        case _movementArticleAmount = "movementArticleAmount"
    }

    required init() {
        super.init()
    }
    
    override func decode(row: PostgresRow) {
        movementArticleId = row.column("movementArticleId")?.int ?? 0
        movementId = row.column("movementId")?.int ?? 0
        movementArticleBarcode = row.column("movementArticleBarcode")?.string ?? ""
        movementArticleQuantity = row.column("movementArticleQuantity")?.double ?? 0
        movementArticleDelivered = row.column("movementArticleDelivered")?.double ?? 0
        movementArticlePrice = row.column("movementArticlePrice")?.double ?? 0
        movementArticleUpdated = row.column("movementArticleUpdated")?.int ?? 0
        movementArticleProduct = try! row.column("movementArticleProduct")?.jsonb(as: Product.self) ?? movementArticleProduct
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        movementArticleId = try container.decodeIfPresent(Int.self, forKey: .movementArticleId) ?? 0
        movementId = try container.decodeIfPresent(Int.self, forKey: .movementId) ?? 0
        movementArticleBarcode = try container.decode(String.self, forKey: .movementArticleBarcode)
        movementArticleProduct = try container.decodeIfPresent(Product.self, forKey: .movementArticleProduct) ?? Product()
        movementArticleQuantity = try container.decode(Double.self, forKey: .movementArticleQuantity)
        movementArticleDelivered = try container.decode(Double.self, forKey: .movementArticleDelivered)
        movementArticlePrice = try container.decode(Double.self, forKey: .movementArticlePrice)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(movementArticleId, forKey: .movementArticleId)
        try container.encode(movementId, forKey: .movementId)
        try container.encode(movementArticleBarcode, forKey: .movementArticleBarcode)
        try container.encode(movementArticleProduct, forKey: .movementArticleProduct)
        try container.encode(movementArticleQuantity, forKey: .movementArticleQuantity)
        try container.encode(movementArticleDelivered, forKey: .movementArticleDelivered)
        try container.encode(movementArticlePrice, forKey: .movementArticlePrice)
        try container.encode(_movementArticleAmount, forKey: ._movementArticleAmount)
    }
}
