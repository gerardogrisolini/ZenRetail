//
//  RegistryController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 13/03/17.
//
//

import Foundation
import ZenNIO

class RegistryController {
	
	private let repository: RegistryProtocol
	
    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as RegistryProtocol

        router.get("/api/registry", handler: registriesHandlerGET)
        router.get("/api/registryfrom/:date", handler: registriesHandlerGET)
		router.get("/api/registry/:id", handler: registryHandlerGET)
		router.post("/api/registry", handler: registryHandlerPOST)
		router.put("/api/registry/:id", handler: registryHandlerPUT)
		router.delete("/api/registry/:id", handler: registryHandlerDELETE)
	}
	
	func registriesHandlerGET(request: HttpRequest, response: HttpResponse) {
        let date: Int = request.getParam("date") ?? 0

        self.repository.getAll(date: date).whenComplete { result in
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
	
	func registryHandlerGET(request: HttpRequest, response: HttpResponse) {
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
	
	func registryHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let data = request.bodyData,
            let item = try? JSONDecoder().decode(Registry.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        self.repository.add(item: item).whenComplete { result in
            do {
                switch result {
                case .success(let id):
                    item.registryId = id
                    try response.send(json: item)
                    response.completed(.created)
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
	}
	
	func registryHandlerPUT(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id"),
            let data = request.bodyData,
            let item = try? JSONDecoder().decode(Registry.self, from: data) else {
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
	
	func registryHandlerDELETE(request: HttpRequest, response: HttpResponse) {
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
}
