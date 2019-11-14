//
//  InvoiceProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 05/04/17.
//
//

import NIO

protocol InvoiceProtocol {
	
	func getPayments() -> [ItemValue]
	
	func getAll() -> EventLoopFuture<[Invoice]>
	
	func get(id: Int) -> EventLoopFuture<Invoice>
	
	func getMovements(invoiceId: Int) -> EventLoopFuture<[Movement]>

	func getMovementArticles(invoiceId: Int) -> EventLoopFuture<[MovementArticle]>
	
	func add(item: Invoice) -> EventLoopFuture<Int>
	
	func update(id: Int, item: Invoice) -> EventLoopFuture<Bool>
	
	func delete(id: Int) -> EventLoopFuture<Bool>
	
	func addMovement(invoiceId: Int, id: Int) -> EventLoopFuture<Bool>
	
	func removeMovement(id: Int) -> EventLoopFuture<Bool>
}
