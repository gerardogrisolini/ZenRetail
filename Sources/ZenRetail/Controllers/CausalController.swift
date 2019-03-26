//
//  CausalController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

import Foundation
import ZenNIO

class CausalController {
    
    private let repository: CausalProtocol
    
    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as CausalProtocol

        router.get("/api/causal", handler: causalsHandlerGET)
		router.get("/api/causalfrom/{date}", handler: causalsHandlerGET)
        router.get("/api/causal/{id}", handler: causalHandlerGET)
        router.post("/api/causal", handler: causalHandlerPOST)
        router.put("/api/causal/{id}", handler: causalHandlerPUT)
        router.delete("/api/causal/{id}", handler: causalHandlerDELETE)
    }
    
    func causalsHandlerGET(request: HttpRequest, response: HttpResponse) {
		do {
            let date = request.getParam(Int.self, key: "date") ?? 0
			let items = try self.repository.getAll(date: date)
            try response.send(json:items)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func causalHandlerGET(request: HttpRequest, response: HttpResponse) {
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
    
    func causalHandlerPOST(request: HttpRequest, response: HttpResponse) {
        do {
            guard let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(Causal.self, from: data)
            try self.repository.add(item: item)
            try response.send(json:item)
            response.completed( .created)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func causalHandlerPUT(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id"),
                let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(Causal.self, from: data)
            try self.repository.update(id: id, item: item)
            try response.send(json:item)
            response.completed( .accepted)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func causalHandlerDELETE(request: HttpRequest, response: HttpResponse) {
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
}
