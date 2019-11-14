//
//  UserRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 18/02/17.
//
//

import Foundation
import ZenPostgres
import NIO

struct UserRepository : UserProtocol {
    
   	func getAll() -> EventLoopFuture<[User]> {
        return User().queryAsync()
    }
    
    func get(id: String) -> EventLoopFuture<User> {
        let rows: EventLoopFuture<[User]> = User().queryAsync(whereclause: "uniqueID = $1", params: [id], cursor: Cursor(limit: 1, offset: 0))
        return rows.flatMapThrowing { users -> User in
            if let user = users.first {
                return user
            }
            throw ZenError.recordNotFound
        }
    }
    
    func add(item: User) -> EventLoopFuture<String> {
        item.uniqueID = UUID().uuidString
        item.password = item.password.encrypted
        return item.saveAsync().map { id -> String in
            item.uniqueID = id as! String
            return item.uniqueID
        }
    }
    
    func update(id: String, item: User) -> EventLoopFuture<Bool> {
        return get(id: id).flatMap { current -> EventLoopFuture<Bool> in
            if (item.password.count >= 8 && item.password.count <= 20) {
                current.password = item.password.encrypted
            }
            current.firstname = item.firstname
            current.lastname = item.lastname
            current.username = item.username
            if (item.password.count < 20) {
                current.password = item.password.encrypted
            }
            current.email = item.email
            
            return current.saveAsync().map { id -> Bool in
                id as! Int > 0
            }
        }
    }
    
    func delete(id: String) -> EventLoopFuture<Bool> {
        return User().deleteAsync(key: "uniqueID", value: id).map { count -> Bool in
            count > 0
        }
    }
}
