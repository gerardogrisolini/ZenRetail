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

    func accountHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: String = request.getParam("id") else {
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

    func accountHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let data = request.bodyData,
            let item = try? JSONDecoder().decode(User.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        self.repository.add(item: item).whenComplete { result in
            do {
                switch result {
                case .success(let id):
                    item.uniqueID = id
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
    
    func accountHandlerPUT(request: HttpRequest, response: HttpResponse) {
        guard let id: String = request.getParam("id"),
            let data = request.bodyData,
            let item = try? JSONDecoder().decode(User.self, from: data) else {
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
    
    func accountHandlerDELETE(request: HttpRequest, response: HttpResponse) {
        guard let id: String = request.getParam("id") else {
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
