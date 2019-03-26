//
//  InvoiceProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 05/04/17.
//
//

protocol InvoiceProtocol {
	
	func getPayments() -> [ItemValue]
	
	func getAll() throws -> [Invoice]
	
	func get(id: Int) throws -> Invoice?
	
	func getMovements(invoiceId: Int) throws -> [Movement]

	func getMovementArticles(invoiceId: Int) throws -> [MovementArticle]
	
	func add(item: Invoice) throws
	
	func update(id: Int, item: Invoice) throws
	
	func delete(id: Int) throws
	
	func addMovement(invoiceId: Int, id: Int) throws
	
	func removeMovement(id: Int) throws
}
