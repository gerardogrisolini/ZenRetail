//
//  StoreController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 27/02/17.
//
//

import Foundation
import ZenNIO

class StoreController {
    
    private let repository: StoreProtocol
    
    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as StoreProtocol

        router.get("/api/store", handler: storesHandlerGET)
        router.get("/api/store/:id", handler: storeHandlerGET)
        router.post("/api/store", handler: storeHandlerPOST)
        router.put("/api/store/:id", handler: storeHandlerPUT)
        router.delete("/api/store/:id", handler: storeHandlerDELETE)
    }
    
    func storesHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            let items = try self.repository.getAll()
            try response.send(json:items)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func storeHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id: Int = request.getParam("id") else {
                throw HttpError.badRequest
            }
            let item = try self.repository.get(id: id)
            try response.send(json:item)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func storeHandlerPOST(request: HttpRequest, response: HttpResponse) {
        do {
            guard let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(Store.self, from: data)
            try self.repository.add(item: item)
            try response.send(json:item)
            response.completed( .created)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func storeHandlerPUT(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id: Int = request.getParam("id"),
                let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(Store.self, from: data)
            try self.repository.update(id: id, item: item)
            try response.send(json:item)
            response.completed( .accepted)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func storeHandlerDELETE(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id: Int = request.getParam("id") else {
                throw HttpError.badRequest
            }
            try self.repository.delete(id: id)
            response.completed( .noContent)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
}
