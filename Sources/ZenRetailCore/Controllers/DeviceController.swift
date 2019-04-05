//
//  DeviceController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 11/04/17.
//
//

import Foundation
import ZenNIO

class DeviceController {
	
	private let repository: DeviceProtocol
	
    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as DeviceProtocol

        router.get("/api/device", handler: devicesHandlerGET)
        router.get("/api/devicefrom/:date", handler: devicesHandlerGET)
		router.get("/api/device/:id", handler: deviceHandlerGET)
		router.post("/api/device", handler: deviceHandlerPOST)
		router.put("/api/device/:id", handler: deviceHandlerPUT)
		router.delete("/api/device/:id", handler: deviceHandlerDELETE)
	}
	
    func devicesHandlerGET(request: HttpRequest, response: HttpResponse) {
        if !request.isAuthenticated() {
            response.completed(.unauthorized)
            return
        }

		do {
            let date = request.getParam(Int.self, key: "date") ?? 0
			let items = try self.repository.getAll(date: date)
			try response.send(json:items)
			response.completed()
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
	
	func deviceHandlerGET(request: HttpRequest, response: HttpResponse) {
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
	
	func deviceHandlerPOST(request: HttpRequest, response: HttpResponse) {
		do {
            guard let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(Device.self, from: data)
            item.idStore = item._store.storeId
            try self.repository.add(item: item)
            try response.send(json:item)
			response.completed( .created)
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
	
	func deviceHandlerPUT(request: HttpRequest, response: HttpResponse) {
		do {
            guard let id = request.getParam(Int.self, key: "id"),
                let data = request.bodyData else {
                throw HttpError.badRequest
            }
			let item = try JSONDecoder().decode(Device.self, from: data)
            item.idStore = item._store.storeId
            try self.repository.update(id: id, item: item)
			try response.send(json:item)
			response.completed( .accepted)
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
	
	func deviceHandlerDELETE(request: HttpRequest, response: HttpResponse) {
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
