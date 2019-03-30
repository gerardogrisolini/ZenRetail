//
//  InvoiceController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 05/04/17.
//
//

import Foundation
import ZenNIO

class InvoiceController {
	
	private let repository: InvoiceProtocol
	
    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as InvoiceProtocol

        router.get("/api/invoicepayment", handler: invoicePaymentsHandlerGET)
		router.get("/api/invoice", handler: invoicesHandlerGET)
        router.get("/api/invoice/:id", handler: invoiceHandlerGET)
		router.post("/api/invoice", handler: invoiceHandlerPOST)
        router.put("/api/invoice/:id", handler: invoiceHandlerPUT)
        router.delete("/api/invoice/:id", handler: invoiceHandlerDELETE)
        router.get("/api/invoicemovement/:id", handler: invoiceMovementHandlerGET)
        router.get("/api/invoicemovementarticle/:id", handler: invoiceMovementArticleHandlerGET)
        router.post("/api/invoicemovement/:id", handler: invoiceMovementHandlerPOST)
        router.delete("/api/invoicemovement/:id", handler: invoiceMovementHandlerDELETE)
	}
	
	func invoicePaymentsHandlerGET(request: HttpRequest, response: HttpResponse) {
		do {
			let items = self.repository.getPayments()
			try response.send(json:items)
			response.completed()
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
	
	func invoicesHandlerGET(request: HttpRequest, response: HttpResponse) {
		do {
			let items = try self.repository.getAll()
			try response.send(json:items)
			response.completed()
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
	
	func invoiceHandlerGET(request: HttpRequest, response: HttpResponse) {
		do {
            guard let id = request.getParam(Int.self, key: "id") else {
                throw HttpError.badRequest
            }
			let item = try self.repository.get(id: id)
			try response.send(json:item)
			response.completed()
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
	
	func invoiceHandlerPOST(request: HttpRequest, response: HttpResponse) {
		do {
            guard let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(Invoice.self, from: data)
			try self.repository.add(item: item)
			try response.send(json:item)
			response.completed( .created)
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
	
	func invoiceHandlerPUT(request: HttpRequest, response: HttpResponse) {
		do {
            guard let id = request.getParam(Int.self, key: "id"),
                let data = request.bodyData else {
                    throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(Invoice.self, from: data)
            try self.repository.update(id: id, item: item)
			try response.send(json:item)
			response.completed( .accepted)
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
	
	func invoiceHandlerDELETE(request: HttpRequest, response: HttpResponse) {
		do {
            guard let id = request.getParam(Int.self, key: "id") else {
                throw HttpError.badRequest
            }
			try self.repository.delete(id: id)
			response.completed( .noContent)
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
	
	func invoiceMovementHandlerGET(request: HttpRequest, response: HttpResponse) {
		do {
            guard let id = request.getParam(Int.self, key: "id") else {
                throw HttpError.badRequest
            }
			let items = try self.repository.getMovements(invoiceId: id)
			try response.send(json:items)
			response.completed()
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
	
	func invoiceMovementArticleHandlerGET(request: HttpRequest, response: HttpResponse) {
		do {
            guard let id = request.getParam(Int.self, key: "id") else {
                throw HttpError.badRequest
            }
			let items = try self.repository.getMovementArticles(invoiceId: id)
			try response.send(json:items)
			response.completed()
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
	
	func invoiceMovementHandlerPOST(request: HttpRequest, response: HttpResponse) {
		do {
            guard let id = request.getParam(Int.self, key: "id"),
                let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let json = try JSONDecoder().decode([String:String].self, from: data)
            let value = Int(json["value"]!)!
			try self.repository.addMovement(invoiceId: id, id: value)
            try response.send(json: data)
			response.completed( .created)
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
	
	func invoiceMovementHandlerDELETE(request: HttpRequest, response: HttpResponse) {
		do {
            guard let id = request.getParam(Int.self, key: "id") else {
                throw HttpError.badRequest
            }
			try self.repository.removeMovement(id: id)
			response.completed( .noContent)
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
}
