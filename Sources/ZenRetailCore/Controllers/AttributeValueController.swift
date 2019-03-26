//
//  AttributeValueController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import ZenNIO

class AttributeValueController {
    
    private let repository: AttributeValueProtocol
    
    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as AttributeValueProtocol

        router.get("/api/attributevalue", handler: attributevaluesHandlerGET)
        router.get("/api/attributevalue/{id}", handler: attributevalueHandlerGET)
        router.post("/api/attributevalue", handler: attributevalueHandlerPOST)
        router.put("/api/attributevalue/{id}", handler: attributevalueHandlerPUT)
        router.delete("/api/attributevalue/{id}", handler: attributevalueHandlerDELETE)
    }

    func attributevaluesHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            let items = try self.repository.getAll()
            try response.send(json: items)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func attributevalueHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id") else {
                throw HttpError.badRequest
            }
            let item = try self.repository.get(id: id)
            try response.send(json: item)
            response.completed()
        } catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    func attributevalueHandlerPOST(request: HttpRequest, response: HttpResponse) {
        do {
            guard let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(AttributeValue.self, from: data)
            try self.repository.add(item: item)
            try response.send(json: item)
            response.completed(.created)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    func attributevalueHandlerPUT(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id"),
                let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(AttributeValue.self, from: data)
            try self.repository.update(id: id, item: item)
            try response.send(json: item)
            response.completed(.accepted)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    func attributevalueHandlerDELETE(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id") else {
                throw HttpError.badRequest
            }
            try self.repository.delete(id: id)
            response.completed(.noContent)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
}
