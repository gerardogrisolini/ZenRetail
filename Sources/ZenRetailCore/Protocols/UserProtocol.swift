//
//  AccountProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 18/02/17.
//

protocol UserProtocol {
    
    func getAll() throws -> [User]
    
    func get(id: String) throws -> User?
    
    func add(item: User) throws
    
    func update(id: String, item: User) throws
    
    func delete(id: String) throws
}
