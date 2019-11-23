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
            try response.send(json: items)
            response.success()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
	}
	
	func invoicesHandlerGET(request: HttpRequest, response: HttpResponse) {
        self.repository.getAll().whenComplete { result in
            do {
                switch result {
                case .success(let items):
                    try response.send(json: items)
                    response.success()
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
	}
	
	func invoiceHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }
        
        self.repository.get(id: id).whenComplete { result in
            do {
                switch result {
                case .success(let item):
                    try response.send(json: item)
                    response.success()
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
	}
	
	func invoiceHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let data = request.bodyData,
            let item = try? JSONDecoder().decode(Invoice.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        self.repository.add(item: item).whenComplete { result in
            do {
                switch result {
                case .success(let id):
                    item.invoiceId = id
                    try response.send(json: item)
                    response.success(.created)
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
	}
	
	func invoiceHandlerPUT(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id"),
            let data = request.bodyData,
            let item = try? JSONDecoder().decode(Invoice.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        self.repository.update(id: id, item: item).whenComplete { result in
            do {
                switch result {
                case .success(_):
                    try response.send(json: item)
                    response.success(.accepted)
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
	}
	
	func invoiceHandlerDELETE(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }

        self.repository.delete(id: id).whenComplete { result in
            switch result {
            case .success(let deleted):
                response.success(deleted ? .noContent : .expectationFailed)
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
	}
	
	func invoiceMovementHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }
        
        self.repository.getMovements(invoiceId: id).whenComplete { result in
            do {
                switch result {
                case .success(let items):
                    try response.send(json: items)
                    response.success()
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
	}
	
	func invoiceMovementArticleHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }
        
        self.repository.getMovementArticles(invoiceId: id).whenComplete { result in
            do {
                switch result {
                case .success(let items):
                    try response.send(json: items)
                    response.success()
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
	}
	
	func invoiceMovementHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id"),
            let data = request.bodyData,
            let json = try? JSONDecoder().decode([String:String].self, from: data),
            let value = json["value"] else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }
        
        self.repository.addMovement(invoiceId: id, id: Int(value)!).whenComplete { result in
            do {
                switch result {
                case .success(let items):
                    try response.send(json: items)
                    response.success()
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
	}
	
	func invoiceMovementHandlerDELETE(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }

        self.repository.delete(id: id).whenComplete { result in
            switch result {
            case .success(let deleted):
                response.success(deleted ? .noContent : .expectationFailed)
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
	}
}
