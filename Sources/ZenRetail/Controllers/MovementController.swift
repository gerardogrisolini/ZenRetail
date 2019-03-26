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
        router.get("/api/movementwhouse/{date}/{store}", handler: movementsWhouseHandlerGET)
		router.post("/api/movementsales", handler: movementsSalesHandlerPOST)
		router.post("/api/movementreceipted", handler: movementsReceiptedHandlerPOST)
		router.get("/api/movement/{id}", handler: movementHandlerGET)
        router.get("/api/movement/{id}/cost/{shippingId}", handler: movementShippingCostHandlerGET)
		router.get("/api/movementfrom/{date}", handler: movementFromHandlerGET)
		router.get("/api/movementregistry/{id}", handler: movementRegistryHandlerGET)
        router.post("/api/movement", handler: movementHandlerPOST)
		router.post("/api/movement/{id}", handler: movementCloneHandlerPOST)
        router.put("/api/movement/{id}", handler: movementHandlerPUT)
        router.delete("/api/movement/{id}", handler: movementHandlerDELETE)
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
        do {
            guard let id = request.getParam(Int.self, key: "id"),
                let shippingId = request.getParam(String.self, key: "shippingId") else {
                throw HttpError.badRequest
            }
            let item = try self.repository.get(id: id)!
            let cost = (ZenIoC.shared.resolve() as EcommerceProtocol).getShippingCost(id: shippingId, registry: item.movementRegistry)
            try response.send(json:cost)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
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
        do {
			let items = try self.repository.getAll()
            try response.send(json:items)
            response.completed()
        } catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    func movementsWhouseHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            guard let date = request.getParam(String.self, key: "date"),
                let store = request.getParam(Int.self, key: "store") else {
                throw HttpError.badRequest
            }
            let items = try self.repository.getWarehouse(date: date.DateToInt(), store: store)
            try response.send(json:items)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    func movementsSalesHandlerPOST(request: HttpRequest, response: HttpResponse) {
		do {
            guard let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let period = try JSONDecoder().decode(Period.self, from: data)
           	let items = try self.repository.getSales(period: period)
			try response.send(json:items)
			response.completed()
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
	
	func movementsReceiptedHandlerPOST(request: HttpRequest, response: HttpResponse) {
		do {
            guard let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let period = try JSONDecoder().decode(Period.self, from: data)
            let items = try self.repository.getReceipted(period: period)
			try response.send(json:items)
			response.completed()
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
	
	func movementHandlerGET(request: HttpRequest, response: HttpResponse) {
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
    
	func movementRegistryHandlerGET(request: HttpRequest, response: HttpResponse) {
		do {
            guard let id = request.getParam(Int.self, key: "id") else {
                throw HttpError.badRequest
            }
			let items = try self.repository.get(registryId: id)
			try response.send(json:items)
			response.completed()
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
	
	func movementHandlerPOST(request: HttpRequest, response: HttpResponse) {
        do {
            guard let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(Movement.self, from: data)
			try self.repository.add(item: item)
            try response.send(json:item)
			
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
			
            response.completed( .created)
        } catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
	func movementCloneHandlerPOST(request: HttpRequest, response: HttpResponse) {
		do {
            guard let id = request.getParam(Int.self, key: "id") else {
                throw HttpError.badRequest
            }
			let item = try self.repository.clone(sourceId: id)
            let price = item.movementCausal.causalQuantity > 0 ? "purchase" : "selling"
            try self.articleRepository.clone(sourceMovementId: id, targetMovementId: item.movementId, price: price)
			try response.send(json:item)
			response.completed( .created)
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}

	func movementHandlerPUT(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id"),
                let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(Movement.self, from: data)
            try self.repository.update(id: id, item: item)
            try response.send(json:item)
            response.completed( .accepted)
        } catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func movementHandlerDELETE(request: HttpRequest, response: HttpResponse) {
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

    func movementFromHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            guard let date = request.getParam(Int.self, key: "date") else {
                throw HttpError.badRequest
            }
            if let basic = request.session?.token?.basic {
                let apiKey = basic.split(separator: ":")
                let items = try self.repository.getAll(
                    device: apiKey[0].description,
                    user: apiKey[1].description,
                    date: date
                )
                try response.send(json:items)
                response.completed()
            } else {
                response.completed( .unauthorized)
            }
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
}
