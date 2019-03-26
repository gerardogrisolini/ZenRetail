//
//  StoreProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 27/02/17.
//

protocol StoreProtocol {
    
    func getAll() throws -> [Store]
    
    func get(id: Int) throws -> Store?
    
    func add(item: Store) throws
    
    func update(id: Int, item: Store) throws
    
    func delete(id: Int) throws
}
