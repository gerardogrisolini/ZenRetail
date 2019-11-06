//
//  EcommerceProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 25/10/17.
//

import NIO

struct Cost: Codable {
    public var value: Double
}

struct Item: Codable {
    public var id: String
    public var value: String
}

struct Order: Codable {
    public var shipping: String
    public var shippingCost: Double
    public var payment: String
}

protocol EcommerceProtocol {
    
    func getSettings() -> EventLoopFuture<Setting>
    
    func getBrands() -> EventLoopFuture<[Brand]>

    func getCategories() -> EventLoopFuture<[Category]>

    func getProductsNews() -> EventLoopFuture<[Product]>

    func getProductsFeatured() -> EventLoopFuture<[Product]>

    func getProductsDiscount() -> EventLoopFuture<[Product]>

    func getProducts(category: String) -> EventLoopFuture<[Product]>

    func getProducts(brand: String) -> EventLoopFuture<[Product]>

    func getProduct(name: String) -> EventLoopFuture<Product>

    func findProducts(text: String) -> EventLoopFuture<[Product]>
    
    func getBaskets() -> EventLoopFuture<[Basket]>

    func getBasket(registryId: Int) -> EventLoopFuture<[Basket]>
    
    func addBasket(item: Basket) -> EventLoopFuture<Basket>

    func updateBasket(id: Int, item: Basket) -> EventLoopFuture<Bool>
    
    func deleteBasket(id: Int) -> EventLoopFuture<Bool>


    func getPayments() -> [Item]
    
    func getShippings() -> [Item]
    
    func getShippingCost(id: String, registry: Registry) -> EventLoopFuture<Cost>
    
    
    func addOrder(registryId: Int, order: OrderModel) -> EventLoopFuture<Movement>

    func getOrders(registryId: Int) -> EventLoopFuture<[Movement]>

    func getOrder(registryId: Int, id: Int) -> EventLoopFuture<Movement>

    func getOrderItems(registryId: Int, id: Int) -> EventLoopFuture<[MovementArticle]>
}

