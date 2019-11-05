//
//  BrandProtocol.swift
//  PerfectTurnstilePostgreSQLDemo
//
//  Created by Gerardo Grisolini on 16/02/17.
//
//

import NIO

protocol BrandProtocol {
    
    func getAll() -> EventLoopFuture<[Brand]>
    //func getAll() throws -> [Brand]

    func get(id: Int) -> EventLoopFuture<Brand>
    
    func add(item: Brand) -> EventLoopFuture<Int>
    
    func update(id: Int, item: Brand) -> EventLoopFuture<Bool>
    
    func delete(id: Int) -> EventLoopFuture<Bool>
}
