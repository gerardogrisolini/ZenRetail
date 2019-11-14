//
//  TarGroupProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 07/11/17.
//

import NIO

protocol TagGroupProtocol {
    
    func getAll() -> EventLoopFuture<[TagGroup]>
    
    func getAllAndValues() -> EventLoopFuture<[TagGroup]>
    
    func get(id: Int) -> EventLoopFuture<TagGroup>
    
    func getValues(id: Int) -> EventLoopFuture<[TagValue]>
    
    func add(item: TagGroup) -> EventLoopFuture<Int>
    
    func update(id: Int, item: TagGroup) -> EventLoopFuture<Bool>
    
    func delete(id: Int) -> EventLoopFuture<Bool>
}
