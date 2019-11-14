//
//  AccountProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 18/02/17.
//

import NIO

protocol UserProtocol {
    
    func getAll() -> EventLoopFuture<[User]>
    
    func get(id: String) -> EventLoopFuture<User>
    
    func add(item: User) -> EventLoopFuture<String>
    
    func update(id: String, item: User) -> EventLoopFuture<Bool>
    
    func delete(id: String) -> EventLoopFuture<Bool>
}
