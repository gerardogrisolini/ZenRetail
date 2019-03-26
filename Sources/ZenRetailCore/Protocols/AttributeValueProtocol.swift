//
//  AttributeValueProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

protocol AttributeValueProtocol {
    
    func getAll() throws -> [AttributeValue]
    
    func get(id: Int) throws -> AttributeValue?
    
    func add(item: AttributeValue) throws
    
    func update(id: Int, item: AttributeValue) throws
    
    func delete(id: Int) throws
}
