//
//  Basket.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 25/10/17.
//å

import Foundation
import PostgresNIO
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

    override func decode(row: PostgresRow) {
        basketId = row.column("basketId")?.int ?? 0
        registryId = row.column("registryId")?.int ?? 0
        basketBarcode = row.column("basketBarcode")?.string ?? ""
        basketQuantity = Double(row.column("basketQuantity")?.float ?? 0)
        basketPrice = Double(row.column("basketPrice")?.float ?? 0)
        basketUpdated = row.column("basketUpdated")?.int ?? 0
        basketProduct = try! row.column("basketProduct")?.jsonb(as: Product.self) ?? basketProduct
        _registry.decode(row: row)
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        basketId = try container.decodeIfPresent(Int.self, forKey: .basketId) ?? 0
        registryId = try container.decodeIfPresent(Int.self, forKey: .registryId) ?? 0
        _registry = try container.decodeIfPresent(Registry.self, forKey: ._registry) ?? Registry()
        basketBarcode = try container.decode(String.self, forKey: .basketBarcode)
        basketQuantity = try container.decode(Double.self, forKey: .basketQuantity)
        basketPrice = try container.decodeIfPresent(Double.self, forKey: .basketPrice) ?? 0
        basketUpdated = try container.decodeIfPresent(Int.self, forKey: .basketUpdated) ?? 0

//        if let product = try container.decodeIfPresent(Product.self, forKey: .basketProduct) {
//            basketProduct = product
//        } else {
//            getProduct(barcode: basketBarcode).whenSuccess { product in
//                basketProduct = product
//            }
//        }
        basketProduct = try container.decode(Product.self, forKey: .basketProduct)
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

//    func getProduct(barcode: String) -> EventLoopFuture<Product> {
//        func getProduct() -> EventLoopFuture<Product> {
//            let product = Product(connection: connection!)
//            return product.get(barcode: barcode).map { () -> Product in
//                return product
//            }
//        }
//
//        if connection == nil {
//            return ZenPostgres.pool.connect().flatMap { conn -> EventLoopFuture<Product> in
//                self.connection = conn
//                defer { conn.disconnect() }
//                return getProduct()
//            }
//        }
//        
//        return getProduct()
//    }
}

