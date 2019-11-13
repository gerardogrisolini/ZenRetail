//
//  AttributeProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import NIO

protocol AttributeProtocol {
    
    func getAll() -> EventLoopFuture<[Attribute]>
    
    func get(id: Int) -> EventLoopFuture<Attribute>
    
    func getValues(id: Int) -> EventLoopFuture<[AttributeValue]>

    func add(item: Attribute) -> EventLoopFuture<Int>
    
    func update(id: Int, item: Attribute) -> EventLoopFuture<Bool>
    
    func delete(id: Int) -> EventLoopFuture<Bool>
}
