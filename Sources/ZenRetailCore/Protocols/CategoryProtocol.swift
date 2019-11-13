//
//  CategoryProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import NIO

protocol CategoryProtocol {
    
    func getAll() -> EventLoopFuture<[Category]>
    
    func get(id: Int) -> EventLoopFuture<Category>
    
    func add(item: Category) -> EventLoopFuture<Int>
    
    func update(id: Int, item: Category) -> EventLoopFuture<Bool>
    
    func delete(id: Int) -> EventLoopFuture<Bool>
}
