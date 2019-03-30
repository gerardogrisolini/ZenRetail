//
//  TagController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 07/11/17.
//

import Foundation
import ZenNIO

class TagGroupController {
    
    private let repository: TagGroupProtocol
    
    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as TagGroupProtocol

        router.get("/api/tag", handler: tagsHandlerGET)
        router.get("/api/tag/:id", handler: tagHandlerGET)
        router.get("/api/tag/:id/value", handler: tagValueHandlerGET)
        router.post("/api/tag", handler: tagHandlerPOST)
        router.put("/api/tag/:id", handler: tagHandlerPUT)
        router.delete("/api/tag/:id", handler: tagHandlerDELETE)
    }
    
    func tagsHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            let items = try self.repository.getAll()
            try response.send(json:items)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func tagAllHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            let items = try self.repository.getAll()
            for item in items {
                item._values = try self.repository.getValues(id: item.tagGroupId)
            }
            try response.send(json:items)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    func tagHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(String.self, key: "id") else {
                throw HttpError.badRequest
            }
            if id == "all" {
                let items = try self.repository.getAll()
                for item in items {
                    item._values = try self.repository.getValues(id: item.tagGroupId)
                }
                try response.send(json:items)
            } else {
                let item = try self.repository.get(id: Int(id)!)
                try response.send(json:item)
            }
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func tagValueHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id") else {
                throw HttpError.badRequest
            }
            let item = try self.repository.getValues(id: id)
            try response.send(json:item)
            response.completed( .created)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func tagHandlerPOST(request: HttpRequest, response: HttpResponse) {
        do {
            guard let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(TagGroup.self, from: data)
            try self.repository.add(item: item)
            try response.send(json:item)
            response.completed( .created)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func tagHandlerPUT(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id"),
                let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(TagGroup.self, from: data)
            try self.repository.update(id: id, item: item)
            try response.send(json:item)
            response.completed( .accepted)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func tagHandlerDELETE(request: HttpRequest, response: HttpResponse) {
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

