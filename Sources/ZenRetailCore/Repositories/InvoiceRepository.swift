//
//  InvoiceRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 05/04/17.
//
//

import ZenPostgres

struct InvoiceRepository : InvoiceProtocol {
	
	func getPayments() -> [ItemValue] {
		var status = [ItemValue]()
		status.append(ItemValue(value: "Paid"))
		status.append(ItemValue(value: "Bank transfer 30 day"))
		status.append(ItemValue(value: "Bank transfer 60 day"))
		status.append(ItemValue(value: "Bank transfer 90 day"))		
		status.append(ItemValue(value: "Bank receipt 30 day"))
		status.append(ItemValue(value: "Bank receipt 60 day"))
		status.append(ItemValue(value: "Bank receipt 90 day"))
		status.append(ItemValue(value: "Bank receipt 30 60 day"))
		status.append(ItemValue(value: "Bank receipt 60 90 day"))
		status.append(ItemValue(value: "Bank receipt 30 60 90 day"))
		status.append(ItemValue(value: "Bank receipt 30 60 90 120 day"))
		return status
	}

	func getAll() throws -> [Invoice] {
		let items = Invoice()
		return try items.query()
	}
	
	func get(id: Int) throws -> Invoice? {
		let item = Invoice()
		try item.get(id)
		
		return item
	}
	
	func getMovements(invoiceId: Int) throws -> [Movement] {
		return try Movement().query(whereclause: "idInvoice = $1", params: [invoiceId])
	}
	
	func getMovementArticles(invoiceId: Int) throws -> [MovementArticle] {
		let join = DataSourceJoin(
			table: "Movement",
			onCondition:"MovementArticle.movementId = Movement.movementId",
			direction: .INNER);

		return try MovementArticle().query(whereclause: "Movement.idInvoice = $1",
		                params: [invoiceId],
		                joins: [join])
	}

	func add(item: Invoice) throws {
		if item.invoiceNumber == 0 {
			try item.makeNumber()
		}
		item.invoiceUpdated = Int.now()
		try item.save {
			id in item.invoiceId = id as! Int
		}
	}
	
	func update(id: Int, item: Invoice) throws {
		
		guard let current = try get(id: id) else {
			throw ZenError.noRecordFound
		}
		
		item.invoiceUpdated = Int.now()
		current.invoiceNumber = item.invoiceNumber
		current.invoiceDate = item.invoiceDate
		current.invoicePayment = item.invoicePayment
		current.invoiceRegistry = item.invoiceRegistry
		current.invoiceNote = item.invoiceNote
		current.invoiceUpdated = item.invoiceUpdated
		try current.save()
	}
	
	func delete(id: Int) throws {
		let movement = Movement()
		_ = try movement.update(cols: ["idInvoice"], params: [0], id: "idInvoice", value: id)

		let item = Invoice()
		item.invoiceId = id
		try item.delete()
	}
	
	func addMovement(invoiceId: Int, id: Int) throws {
		let movement = Movement()
        _ = try movement.update(cols: ["idInvoice"], params: [invoiceId], id: "movementId", value: id)
	}
	
	func removeMovement(id: Int) throws {
		let movement = Movement()
        _ = try movement.update(cols: ["idInvoice"], params: [0], id: "movementId", value: id)
	}
}
