//
//  TagValueController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 07/11/17.
//

import Foundation
import ZenNIO

class TagValueController {
    
    private let repository: TagValueProtocol
    
    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as TagValueProtocol

        router.get("/api/tagvalue", handler: tagvaluesHandlerGET)
        router.get("/api/tagvalue/{id}", handler: tagvalueHandlerGET)
        router.post("/api/tagvalue", handler: tagvalueHandlerPOST)
        router.put("/api/tagvalue/{id}", handler: tagvalueHandlerPUT)
        router.delete("/api/tagvalue/{id}", handler: tagvalueHandlerDELETE)
    }
    
    func tagvaluesHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            let items = try self.repository.getAll()
            try response.send(json:items)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func tagvalueHandlerGET(request: HttpRequest, response: HttpResponse) {
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
    
    func tagvalueHandlerPOST(request: HttpRequest, response: HttpResponse) {
        do {
            guard let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(TagValue.self, from: data)
            try self.repository.add(item: item)
            try response.send(json:item)
            response.completed( .created)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func tagvalueHandlerPUT(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id"),
                let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(TagValue.self, from: data)
            try self.repository.update(id: id, item: item)
            try response.send(json:item)
            response.completed( .accepted)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func tagvalueHandlerDELETE(request: HttpRequest, response: HttpResponse) {
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

