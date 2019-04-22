//
//  ProductProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

protocol ProductProtocol {
    
    func getTaxes() throws -> [Tax]
    
    func getProductTypes() throws -> [ItemValue]

    func getAll(date: Int) throws -> [Product]
    
    func getAmazonChanges() throws -> [Product]
    
    func get(id: Int) throws -> Product

    func get(barcode: String) throws -> Product

    func add(item: Product) throws
    
    func sync(item: Product) throws -> Product

    func syncImport(item: Product) throws -> Result
    
    func update(id: Int, item: Product) throws
    
    func delete(id: Int) throws

    func reset(id: Int) throws
    
    /*
	func addAttribute(item: ProductAttribute) throws
    
    func removeAttribute(item: ProductAttribute) throws

    func addAttributeValue(item: ProductAttributeValue) throws
    
    func removeAttributeValue(item: ProductAttributeValue) throws
    */
}
