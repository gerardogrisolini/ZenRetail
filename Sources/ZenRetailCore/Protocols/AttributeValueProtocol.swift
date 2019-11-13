//
//  AttributeValueProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import NIO

protocol AttributeValueProtocol {
    
    func getAll() -> EventLoopFuture<[AttributeValue]>
    
    func get(id: Int) -> EventLoopFuture<AttributeValue>
    
    func add(item: AttributeValue) -> EventLoopFuture<Int>
    
    func update(id: Int, item: AttributeValue) -> EventLoopFuture<Bool>
    
    func delete(id: Int) -> EventLoopFuture<Bool>
}
