//
//  MovementArticleProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

import NIO
import PostgresNIO

protocol MovementArticleProtocol {
    
    func get(movementId: Int, connection: PostgresConnection) -> EventLoopFuture<[MovementArticle]>
    
    func get(id: Int, connection: PostgresConnection) -> EventLoopFuture<MovementArticle>
    
    func add(item: MovementArticle, price: String, connection: PostgresConnection) -> EventLoopFuture<Int>
    
    func update(id: Int, item: MovementArticle, connection: PostgresConnection) -> EventLoopFuture<Bool>
    
    func delete(id: Int, connection: PostgresConnection) -> EventLoopFuture<Bool>

	func clone(sourceMovementId: Int, targetMovementId: Int, price: String, connection: PostgresConnection) -> EventLoopFuture<Void>
}
