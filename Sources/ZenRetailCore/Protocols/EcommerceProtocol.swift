//
//  EcommerceProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 25/10/17.
//

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
    
    func getCategories() throws -> [Category]

    func getBrands() throws -> [Brand]

    
    func getProductsNews() throws -> [Product]

    func getProductsFeatured() throws -> [Product]

    func getProductsDiscount() throws -> [Product]

    func getProducts(category: String) throws -> [Product]

    func getProducts(brand: String) throws -> [Product]

    func getProduct(name: String) throws -> Product

    func findProducts(text: String) throws -> [Product]
    
    func getBaskets() throws -> [Basket]

    func getBasket(registryId: Int) throws -> [Basket]
    
    func addBasket(item: Basket) throws

    func updateBasket(id: Int, item: Basket) throws
    
    func deleteBasket(id: Int) throws


    func getPayments() throws -> [Item]
    
    func getShippings() throws -> [Item]
    
    func getShippingCost(id: String, registry: Registry) -> Cost
    
    
    func addOrder(registryId: Int, order: OrderModel) throws -> Movement

    func getOrders(registryId: Int) throws -> [Movement]

    func getOrder(registryId: Int, id: Int) throws -> Movement

    func getOrderItems(registryId: Int, id: Int) throws -> [MovementArticle]
}

