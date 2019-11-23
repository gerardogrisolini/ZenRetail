//
//  MovementController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

import Foundation
import NIO
import PostgresNIO
import ZenPostgres
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
            response.success()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
	}
	
    func movementShippingsHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            let status = self.repository.getShippings()
            try response.send(json:status)
            response.success()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    func movementShippingCostHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id"), let shippingId: String = request.getParam("shippingId") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }

        ZenPostgres.pool.connect().whenComplete { res in
            switch res {
            case .success(let conn):
                defer { conn.disconnect() }
                
                self.repository.get(id: id, connection: conn).whenComplete { result in
                    switch result {
                    case .success(let item):
                        let repository = ZenIoC.shared.resolve() as EcommerceProtocol
                        repository.getShippingCost(id: shippingId, registry: item.movementRegistry).whenComplete { res in
                            switch res {
                            case .success(let cost):
                                try! response.send(json: cost)
                                response.success()
                            case .failure(let err):
                                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
                            }
                        }
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
            response.success()
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
                    response.success()
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
                    response.success()
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
                    response.success(.created)
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
                    response.success(.created)
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
  
        ZenPostgres.pool.connect().whenComplete { res in
            switch res {
            case .success(let conn):
                defer { conn.disconnect() }
                
                self.repository.get(id: id, connection: conn).whenComplete { result in
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
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
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
                    response.success()
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
	}
	
	func movementHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let data = request.bodyData,
            let item = try? JSONDecoder().decode(Movement.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        ZenPostgres.pool.connect().whenComplete { res in
            switch res {
            case .success(let conn):
                defer { conn.disconnect() }
                item.connection = conn

                self.repository.add(item: item).whenComplete { result in
                    switch result {
                    case .success(let id):
                        item.movementId = id
                        
                        self.saveArticles(item: item, connection: conn).whenComplete { res in
                           do {
                                switch res {
                                case .success(_):
                                   try response.send(json: item)
                                   response.success(.created)
                                case .failure(let err):
                                   throw err
                                }
                            } catch {
                                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
                            }
                        }
                    case .failure(let err):
                        response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
                    }
                }
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }
    
    func saveArticles(item: Movement, connection: PostgresConnection) -> EventLoopFuture<Bool> {
        var amount = 0.0
        let promise = connection.eventLoop.makePromise(of: Void.self)

        func saveMovement() -> EventLoopFuture<Bool> {
            return item.update(
                cols: ["movementAmount", "movementStatus"],
                params: [amount, item.movementStatus],
                id: "movementId",
                value: item.movementId)
            .map { count -> Bool in
                count > 0
            }
        }
        
        if item._items.count == 0 {
            promise.succeed(())
        } else {
            let price = item.movementCausal.causalQuantity > 0 ? "purchase" : "selling"
            let count = item._items.count - 1
            for (i, row) in item._items.enumerated() {
                row.movementId = item.movementId
                amount += row._movementArticleAmount
                self.articleRepository.add(item: row, price: price, connection: connection).whenComplete { result in
                    if i == count {
                        switch result {
                        case .success(_):
                            promise.succeed(())
                        case .failure(let err):
                            promise.fail(err)
                        }
                    }
                }
            }
        }
        
        return promise.futureResult.flatMap { () -> EventLoopFuture<Bool> in
            if item.movementCausal.causalBooked == 1 && item.movementCausal.causalQuantity == -1 {
                item.movementStatus = "Processing"
                return self.repository.process(movement: item, actionTypes: [.Booking]).flatMap { () -> EventLoopFuture<Bool> in
                    saveMovement()
                }
            } else {
                item.movementStatus = "Completed"
                if item.movementCausal.causalBooked != 0 {
                    return self.repository.process(movement: item, actionTypes: [.Booking]).flatMap { () -> EventLoopFuture<Bool> in
                        saveMovement()
                    }
                } else if item.movementCausal.causalQuantity != 0 {
                    return self.repository.process(movement: item, actionTypes: [.Delivering, .Stoking]).flatMap { () -> EventLoopFuture<Bool> in
                        saveMovement()
                    }
                }
                return connection.eventLoop.future(false)
            }
        }
    }
    
	func movementCloneHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }

        ZenPostgres.pool.connect().whenComplete { res in
            switch res {
            case .success(let conn):
                defer { conn.disconnect() }
                
                self.repository.clone(sourceId: id, connection: conn).whenComplete { result in
                    switch result {
                    case .success(let item):
                        let price = item.movementCausal.causalQuantity > 0 ? "purchase" : "selling"
                        self.articleRepository.clone(sourceMovementId: id, targetMovementId: item.movementId, price: price, connection: conn).whenComplete { r in
                            do {
                                switch r {
                                case .success(_):
                                    try response.send(json: item)
                                    response.success(.created)
                                case .failure(let err):
                                    throw err
                                }
                            } catch {
                                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
                            }
                        }
                    case .failure(let err):
                        response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
                    }
                }
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
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
                    response.success(.accepted)
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
                response.success(deleted ? .noContent : .expectationFailed)
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
                    response.success()
                case .failure(let err):
                    response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
                }
            }
        } else {
            response.success(.unauthorized)
        }
    }
}
