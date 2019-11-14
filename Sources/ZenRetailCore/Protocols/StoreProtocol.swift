//
//  StoreProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 27/02/17.
//

import NIO

protocol StoreProtocol {
    
    func getAll() -> EventLoopFuture<[Store]>
    
    func get(id: Int) -> EventLoopFuture<Store>
    
    func add(item: Store) -> EventLoopFuture<Int>
    
    func update(id: Int, item: Store) -> EventLoopFuture<Bool>
    
    func delete(id: Int) -> EventLoopFuture<Bool>
}
