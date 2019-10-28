//
//  AttributeController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import ZenNIO

class AttributeController {
    
    private let repository: AttributeProtocol
    
    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as AttributeProtocol

        router.get("/api/attribute", handler: attributesHandlerGET)
        router.get("/api/attribute/:id", handler: attributeHandlerGET)
        router.get("/api/attribute/:id/value", handler: attributevalueHandlerGET)
        router.post("/api/attribute", handler: attributeHandlerPOST)
        router.put("/api/attribute/:id", handler: attributeHandlerPUT)
        router.delete("/api/attribute/:id", handler: attributeHandlerDELETE)
    }

    func attributesHandlerGET(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            do {
                let items = try self.repository.getAll()
                try response.send(json: items)
                response.completed()
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }
    
    func attributeHandlerGET(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            do {
                guard let id: Int = request.getParam("id") else {
                    throw HttpError.badRequest
                }
                let item = try self.repository.get(id: id)
                try response.send(json: item)
                response.completed()
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func attributevalueHandlerGET(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            do {
                guard let id: Int = request.getParam("id") else {
                    throw HttpError.badRequest
                }
                let item = try self.repository.getValues(id: id)
                try response.send(json: item)
                response.completed(.created)
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func attributeHandlerPOST(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            do {
                guard let data = request.bodyData else {
                    throw HttpError.badRequest
                }
                let item = try JSONDecoder().decode(Attribute.self, from: data)
                try self.repository.add(item: item)
                try response.send(json: item)
                response.completed(.created)
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func attributeHandlerPUT(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            do {
                guard let id: Int = request.getParam("id"),
                    let data = request.bodyData else {
                    throw HttpError.badRequest
                }
                let item = try JSONDecoder().decode(Attribute.self, from: data)
                try self.repository.update(id: id, item: item)
                try response.send(json: item)
                response.completed(.accepted)
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func attributeHandlerDELETE(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            do {
                guard let id: Int = request.getParam("id") else {
                    throw HttpError.badRequest
                }
                try self.repository.delete(id: id)
                response.completed(.noContent)
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }
}
