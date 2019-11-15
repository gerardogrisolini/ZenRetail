//
//  InvoiceRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 05/04/17.
//
//

import NIO
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

	func getAll() -> EventLoopFuture<[Invoice]> {
		return Invoice().query()
	}
	
	func get(id: Int) -> EventLoopFuture<Invoice> {
		let item = Invoice()
        return item.get(id).map { () -> Invoice in
            return item
        }
	}
	
	func getMovements(invoiceId: Int) -> EventLoopFuture<[Movement]> {
		return Movement().query(whereclause: "idInvoice = $1", params: [invoiceId])
	}
	
	func getMovementArticles(invoiceId: Int) -> EventLoopFuture<[MovementArticle]> {
		let join = DataSourceJoin(
			table: "Movement",
			onCondition:"MovementArticle.movementId = Movement.movementId",
			direction: .INNER);

		return MovementArticle().query(whereclause: "Movement.idInvoice = $1",
                                       params: [invoiceId],
                                       joins: [join])
	}

	func add(item: Invoice) -> EventLoopFuture<Int> {
        func saveItem() -> EventLoopFuture<Int> {
            item.invoiceUpdated = Int.now()
            return item.save().map { id -> Int in
                item.invoiceId = id as! Int
                return item.invoiceId
            }
        }
        
        if item.invoiceNumber == 0 {
            return item.makeNumber().flatMap { () -> EventLoopFuture<Int> in
                return saveItem()
            }
		}
        
        return saveItem()
	}
	
	func update(id: Int, item: Invoice) -> EventLoopFuture<Bool> {
        item.invoiceId = id
		item.invoiceUpdated = Int.now()
        return item.save().map { id -> Bool in
            id as! Int > 0
        }
	}
	
	func delete(id: Int) -> EventLoopFuture<Bool> {
        return Movement().update(cols: ["idInvoice"], params: [0], id: "idInvoice", value: id).flatMap { count -> EventLoopFuture<Bool> in
            return Invoice().delete(id)
        }
	}
	
	func addMovement(invoiceId: Int, id: Int) -> EventLoopFuture<Bool> {
		return Movement().update(cols: ["idInvoice"], params: [invoiceId], id: "movementId", value: id).map { count -> Bool in
            count > 0
        }
	}
	
	func removeMovement(id: Int) -> EventLoopFuture<Bool> {
        return Movement().update(cols: ["idInvoice"], params: [0], id: "movementId", value: id).map { count -> Bool in
            count > 0
        }
	}
}
