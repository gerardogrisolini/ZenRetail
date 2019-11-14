//
//  MovementProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

import NIO
import PostgresNIO

protocol MovementProtocol {
    
    func getPayments() -> [Item]

    func getShippings() -> [Item]

    func getStatus() -> [ItemValue]

	func getAll() -> EventLoopFuture<[Movement]>
	
    func getAll(device: String, user: String, date: Int) -> EventLoopFuture<[Movement]>
    
    func getWarehouse(date: Int, store: Int) -> EventLoopFuture<[Whouse]>
    
    func getSales(period: Period) -> EventLoopFuture<[MovementArticle]>
	
	func getReceipted(period: Period) -> EventLoopFuture<[Movement]>
	
	func get(registryId: Int) -> EventLoopFuture<[Movement]>

	func get(id: Int, connection: PostgresConnection) -> EventLoopFuture<Movement>
    
    func add(item: Movement) -> EventLoopFuture<Int>
    
    func update(id: Int, item: Movement) -> EventLoopFuture<Bool>
    
    func delete(id: Int) -> EventLoopFuture<Bool>

	func clone(sourceId: Int, connection: PostgresConnection) -> EventLoopFuture<Movement>
	
	func process(movement: Movement, actionTypes: [ActionType]) -> EventLoopFuture<Void>
}
