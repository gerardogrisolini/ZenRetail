//
//  CausalProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

import NIO

protocol CausalProtocol {
    
    func getAll(date: Int) -> EventLoopFuture<[Causal]>
    
    func get(id: Int) -> EventLoopFuture<Causal>
    
    func add(item: Causal) -> EventLoopFuture<Int>
    
    func update(id: Int, item: Causal) -> EventLoopFuture<Bool>
    
    func delete(id: Int) -> EventLoopFuture<Bool>
}
