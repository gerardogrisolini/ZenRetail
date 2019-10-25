//
//  Basket.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 25/10/17.
//å

import Foundation
import PostgresClientKit
import ZenPostgres


class Basket: PostgresTable, Codable {
    
    public var basketId : Int = 0
    public var registryId : Int = 0
    public var basketBarcode : String = ""
    public var basketProduct : Product = Product()
    public var basketQuantity : Double = 0
    public var basketPrice : Double = 0
    public var basketUpdated : Int = Int.now()
    
    public var _registry: Registry = Registry()
    public var _basketAmount: Double {
        return (basketQuantity * basketPrice).roundCurrency()
    }
    
    private enum CodingKeys: String, CodingKey {
        case basketId
        case registryId
        case basketBarcode
        case basketProduct
        case basketQuantity
        case basketPrice
        case _registry = "registry"
        case _basketAmount = "basketAmount"
        case basketUpdated
    }
    
    required init() {
        super.init()
    }

    override func decode(row: Row) {
        basketId = (try? row.columns[0].int()) ?? 0
        registryId = (try? row.columns[1].int()) ?? 0
        basketBarcode = (try? row.columns[2].string()) ?? ""
        if let product = row.columns[3].data {
            basketProduct = try! JSONDecoder().decode(Product.self, from: product)
        }
        basketQuantity = (try? row.columns[4].double()) ?? 0
        basketPrice = (try? row.columns[5].double()) ?? 0
        basketUpdated = (try? row.columns[6].int()) ?? 0
        _ = row.columns.dropFirst(7)
        _registry.decode(row: row)
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        basketId = try container.decodeIfPresent(Int.self, forKey: .basketId) ?? 0
        registryId = try container.decodeIfPresent(Int.self, forKey: .registryId) ?? 0
        _registry = try container.decodeIfPresent(Registry.self, forKey: ._registry) ?? Registry()
        basketBarcode = try container.decode(String.self, forKey: .basketBarcode)
        basketProduct = try container.decodeIfPresent(Product.self, forKey: .basketProduct)
            ?? self.getProduct(barcode: basketBarcode)
        basketQuantity = try container.decode(Double.self, forKey: .basketQuantity)
        basketPrice = try container.decodeIfPresent(Double.self, forKey: .basketPrice) ?? 0
        basketUpdated = try container.decodeIfPresent(Int.self, forKey: .basketUpdated) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(basketId, forKey: .basketId)
        try container.encode(registryId, forKey: .registryId)
        try container.encode(_registry, forKey: ._registry)
        try container.encode(basketBarcode, forKey: .basketBarcode)
        try container.encode(basketProduct, forKey: .basketProduct)
        try container.encode(basketQuantity, forKey: .basketQuantity)
        try container.encode(basketPrice, forKey: .basketPrice)
        try container.encode(_basketAmount, forKey: ._basketAmount)
        try container.encode(basketUpdated, forKey: .basketUpdated)
    }

    func getProduct(barcode: String) throws -> Product {
        let product = db != nil ? Product(db: db!) : Product()
        try product.get(barcode: barcode)
        return product
    }
}

