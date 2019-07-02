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
		do {
            let date: Int = request.getParam("date") ?? 0
			let items = try self.repository.getAll(date: date)
			try response.send(json:items)
			response.completed()
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
	
	func registryHandlerGET(request: HttpRequest, response: HttpResponse) {
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
	
	func registryHandlerPOST(request: HttpRequest, response: HttpResponse) {
		do {
            guard let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(Registry.self, from: data)
            try self.repository.add(item: item)
			try response.send(json:item)
			response.completed( .created)
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
	
	func registryHandlerPUT(request: HttpRequest, response: HttpResponse) {
		do {
            guard let id: Int = request.getParam("id"),
                let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(Registry.self, from: data)
			try self.repository.update(id: id, item: item)
			try response.send(json:item)
			response.completed( .accepted)
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
	
	func registryHandlerDELETE(request: HttpRequest, response: HttpResponse) {
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
