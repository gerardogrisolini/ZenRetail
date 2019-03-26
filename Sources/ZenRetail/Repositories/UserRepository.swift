//
//  UserRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 18/02/17.
//
//

import Foundation
import ZenPostgres

struct UserRepository : UserProtocol {
    
   	func getAll() throws -> [User] {
        let items = User()
        return try items.query()
    }
    
    func get(id: String) throws -> User? {
        let rows: [User] = try User().query(whereclause: "uniqueID = $1", params: [id], cursor: Cursor.init(limit: 1, offset: 0))
        return rows.first
    }
    
    func add(item: User) throws {
        item.uniqueID = UUID().uuidString
        //item.password = BCrypt.hash(password: item.password)
        try item.create()
    }
    
    func update(id: String, item: User) throws {
        
        guard let current = try get(id: id) else {
            throw ZenError.noRecordFound
        }
        
        current.firstname = item.firstname
        current.lastname = item.lastname
        current.username = item.username
        if (item.password.count < 20) {
            current.password = item.password //BCrypt.hash(password: item.password)
        }
        current.email = item.email
        
        try current.save()
    }
    
    func delete(id: String) throws {
        let item = User()
        item.uniqueID = id
        try item.delete()
    }
}
