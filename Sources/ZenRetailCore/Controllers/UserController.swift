//
//  AccountController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 18/02/17.
//
//

import Foundation
import ZenNIO

class UserController {
    
    private let repository: UserProtocol
    
    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as UserProtocol
        
        router.get("/api/account", handler: accountsHandlerGET)
        router.get("/api/account/:id", handler: accountHandlerGET)
        router.post("/api/account", handler: accountHandlerPOST)
        router.put("/api/account/:id", handler: accountHandlerPUT)
        router.delete("/api/account/:id", handler: accountHandlerDELETE)
    }

   func accountsHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            let items = try self.repository.getAll()
            try response.send(json:items)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    func accountHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(String.self, key: "id") else {
                throw HttpError.badRequest
            }
            let item = try self.repository.get(id: id)
            try response.send(json:item)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    func accountHandlerPOST(request: HttpRequest, response: HttpResponse) {
        do {
            guard let data = request.bodyData else {
                    throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(User.self, from: data)
            try self.repository.add(item: item)
            try response.send(json:item)
            response.completed( .created)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func accountHandlerPUT(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(String.self, key: "id"),
                let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(User.self, from: data)
            try self.repository.update(id: id, item: item)
            try response.send(json:item)
            response.completed( .accepted)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func accountHandlerDELETE(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(String.self, key: "id") else {
                throw HttpError.badRequest
            }
            try self.repository.delete(id: id)
            response.completed( .noContent)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
}
