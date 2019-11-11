//
//  ProductProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import NIO

protocol ProductProtocol {
    
    func getTaxes() -> [Tax]
    
    func getProductTypes() -> [ItemValue]

    func getAll(date: Int) -> EventLoopFuture<[Product]>
    
    func getAmazonChanges() -> EventLoopFuture<[Product]>
    
    func get(id: Int) -> EventLoopFuture<Product>

    func get(barcode: String) -> EventLoopFuture<Product>

    func add(item: Product) -> EventLoopFuture<Int>
    
    func update(id: Int, item: Product) -> EventLoopFuture<Bool>

    func sync(item: Product) -> EventLoopFuture<Product>

    func syncImport(item: Product) throws -> EventLoopFuture<Result>
    
    func delete(id: Int) -> EventLoopFuture<Void>

    func reset(id: Int) -> EventLoopFuture<Int> 
    
    /*
	func addAttribute(item: ProductAttribute) throws
    
    func removeAttribute(item: ProductAttribute) throws

    func addAttributeValue(item: ProductAttributeValue) throws
    
    func removeAttributeValue(item: ProductAttributeValue) throws
    */
}
