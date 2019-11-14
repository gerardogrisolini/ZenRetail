//
//  TagValueProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 07/11/17.
//

import NIO

protocol TagValueProtocol {
    
    func getAll() -> EventLoopFuture<[TagValue]>
    
    func get(id: Int) -> EventLoopFuture<TagValue>
    
    func add(item: TagValue) -> EventLoopFuture<Int>
    
    func update(id: Int, item: TagValue) -> EventLoopFuture<Bool>
    
    func delete(id: Int) -> EventLoopFuture<Bool>
}

