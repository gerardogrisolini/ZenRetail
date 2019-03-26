//
//  CategoryProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

protocol CategoryProtocol {
    
    func getAll() throws -> [Category]
    
    func get(id: Int) throws -> Category?
    
    func add(item: Category) throws
    
    func update(id: Int, item: Category) throws
    
    func delete(id: Int) throws
}
