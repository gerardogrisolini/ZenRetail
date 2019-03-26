//
//  MovementProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

protocol MovementProtocol {
    
    func getPayments() -> [Item]

    func getShippings() -> [Item]

    func getStatus() -> [ItemValue]

	func getAll() throws -> [Movement]
	
    func getAll(device: String, user: String, date: Int) throws -> [Movement]
    
    func getWarehouse(date: Int, store: Int) throws -> [Whouse] 
    
    func getSales(period: Period) throws -> [MovementArticle]
	
	func getReceipted(period: Period) throws -> [Movement]
	
	func get(registryId: Int) throws -> [Movement]

	func get(id: Int) throws -> Movement?
    
    func add(item: Movement) throws
    
    func update(id: Int, item: Movement) throws
    
    func delete(id: Int) throws

	func clone(sourceId: Int) throws -> Movement
	
	func process(movement: Movement, actionTypes: [ActionType]) throws
}
