//
//  MovementController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

import Foundation
import ZenNIO

class MovementController {
    
	private let repository: MovementProtocol
	private let articleRepository: MovementArticleProtocol
	
    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as MovementProtocol
        self.articleRepository = ZenIoC.shared.resolve() as MovementArticleProtocol

        router.get("/api/movementshipping", handler: movementShippingsHandlerGET)
        router.get("/api/movementpayment", handler: movementPaymentsHandlerGET)
		router.get("/api/movementstatus", handler: movementStatusHandlerGET)
        router.get("/api/movement", handler: movementsHandlerGET)
        router.get("/api/movementwhouse/:date/:store", handler: movementsWhouseHandlerGET)
		router.post("/api/movementsales", handler: movementsSalesHandlerPOST)
		router.post("/api/movementreceipted", handler: movementsReceiptedHandlerPOST)
		router.get("/api/movement/:id", handler: movementHandlerGET)
        router.get("/api/movement/:id/cost/:shippingId", handler: movementShippingCostHandlerGET)
        router.get("/api/movementfrom/:date", handler: movementFromHandlerGET)
		router.get("/api/movementregistry/:id", handler: movementRegistryHandlerGET)
        router.post("/api/movement", handler: movementHandlerPOST)
		router.post("/api/movement/:id", handler: movementCloneHandlerPOST)
        router.put("/api/movement/:id", handler: movementHandlerPUT)
        router.delete("/api/movement/:id", handler: movementHandlerDELETE)
    }

	func movementPaymentsHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            let status = self.repository.getPayments()
            try response.send(json:status)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
	}
	
    func movementShippingsHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            let status = self.repository.getShippings()
            try response.send(json:status)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    func movementShippingCostHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id"), let shippingId: String = request.getParam("shippingId") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }

        self.repository.get(id: id).whenComplete { result in
            switch result {
            case .success(let item):
                let repository = ZenIoC.shared.resolve() as EcommerceProtocol
                repository.getShippingCost(id: shippingId, registry: item.movementRegistry).whenComplete { res in
                    switch res {
                    case .success(let cost):
                        try! response.send(json: cost)
                        response.completed()
                    case .failure(let err):
                        response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
                    }
                }
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }

    func movementStatusHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            let status = self.repository.getStatus()
            try response.send(json:status)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
	}

	func movementsHandlerGET(request: HttpRequest, response: HttpResponse) {
        self.repository.getAll().whenComplete { result in
            do {
                switch result {
                case .success(let items):
                    try response.send(json: items)
                    response.completed()
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func movementsWhouseHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let date: String = request.getParam("date"),
            let store: Int = request.getParam("store") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter date and/or store")
            return
        }
        
        self.repository.getWarehouse(date: date.DateToInt(), store: store).whenComplete { result in
            do {
                switch result {
                case .success(let item):
                    try response.send(json: item)
                    response.completed()
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func movementsSalesHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let data = request.bodyData,
            let period = try? JSONDecoder().decode(Period.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        self.repository.getSales(period: period).whenComplete { result in
            do {
                switch result {
                case .success(let articles):
                    try response.send(json: articles)
                    response.completed(.created)
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
	}
	
	func movementsReceiptedHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let data = request.bodyData,
            let period = try? JSONDecoder().decode(Period.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        self.repository.getReceipted(period: period).whenComplete { result in
            do {
                switch result {
                case .success(let items):
                    try response.send(json: items)
                    response.completed(.created)
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
	}
	
	func movementHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }
        
        self.repository.get(id: id).whenComplete { result in
            do {
                switch result {
                case .success(let item):
                    try response.send(json: item)
                    response.completed()
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }
    
	func movementRegistryHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }
        
        self.repository.get(registryId: id).whenComplete { result in
            do {
                switch result {
                case .success(let item):
                    try response.send(json: item)
                    response.completed()
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
	}
	
	func movementHandlerPOST(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            if !request.isAuthenticated() {
                response.completed(.unauthorized)
                return
            }

            do {
                guard let data = request.bodyData else {
                    throw HttpError.badRequest
                }
                let item = try JSONDecoder().decode(Movement.self, from: data)
                try self.repository.add(item: item)
                try response.send(json: item)
                
                if item._items.count > 0 {
                    var amount = 0.0
                    let price = item.movementCausal.causalQuantity > 0 ? "purchase" : "selling"
                    for row in item._items {
                        row.movementId = item.movementId
                        try self.articleRepository.add(item: row, price: price)
                        amount += row._movementArticleAmount
                    }
                    
                    if item.movementCausal.causalBooked == 1 && item.movementCausal.causalQuantity == -1 {
                        item.movementStatus = "Processing"
                        try self.repository.process(movement: item, actionTypes: [.Booking])
                    } else {
                        item.movementStatus = "Completed"
                        if item.movementCausal.causalBooked != 0 {
                            try self.repository.process(movement: item, actionTypes: [.Booking])
                        } else if item.movementCausal.causalQuantity != 0 {
                            try self.repository.process(movement: item, actionTypes: [.Delivering, .Stoking])
                        }
                    }

                    _ = try item.update(
                        cols: ["movementAmount", "movementStatus"],
                        params: [amount, item.movementStatus],
                        id: "movementId",
                        value: item.movementId)
                }
                
                response.completed(.created)
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }
    
	func movementCloneHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }

        self.repository.clone(sourceId: id).whenComplete { result in
            do {
                switch result {
                case .success(let item):
                    let price = item.movementCausal.causalQuantity > 0 ? "purchase" : "selling"
                    try self.articleRepository.clone(sourceMovementId: id, targetMovementId: item.movementId, price: price)
                    try response.send(json: item)
                    response.completed(.created)
                case .failure(let err):
                    throw err
                }
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
	}

	func movementHandlerPUT(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id"),
            let data = request.bodyData,
            let item = try? JSONDecoder().decode(Movement.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        self.repository.update(id: id, item: item).whenComplete { result in
            do {
                switch result {
                case .success(_):
                    try response.send(json: item)
                    response.completed(.accepted)
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }
    
    func movementHandlerDELETE(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }

        self.repository.delete(id: id).whenComplete { result in
            switch result {
            case .success(let deleted):
                response.completed(deleted ? .noContent : .expectationFailed)
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }

    func movementFromHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let date: Int = request.getParam("date") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter date")
            return
        }

        let basic = request.authorization.replacingOccurrences(of: "Basic ", with: "")
        let apiKey = basic.split(separator: "#")
        if apiKey.count == 2 {
            self.repository.getAll(
                device: apiKey[0].description,
                user: apiKey[1].description,
                date: date
            ).whenComplete { result in
                switch result {
                case .success(let items):
                    try? response.send(json: items)
                    response.completed()
                case .failure(let err):
                    response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
                }
            }
        } else {
            response.completed(.unauthorized)
        }
    }
}
