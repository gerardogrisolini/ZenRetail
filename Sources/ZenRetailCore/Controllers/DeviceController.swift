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
//        if !request.isAuthenticated() {
//            response.completed(.unauthorized)
//            return
//        }

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
	
	func deviceHandlerGET(request: HttpRequest, response: HttpResponse) {
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
	
	func deviceHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let data = request.bodyData,
            let item = try? JSONDecoder().decode(Device.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        self.repository.add(item: item).whenComplete { result in
            do {
                switch result {
                case .success(let id):
                    item.deviceId = id
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
	
	func deviceHandlerPUT(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id"),
            let data = request.bodyData,
            let item = try? JSONDecoder().decode(Device.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        item.idStore = item._store.storeId
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
	
	func deviceHandlerDELETE(request: HttpRequest, response: HttpResponse) {
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
