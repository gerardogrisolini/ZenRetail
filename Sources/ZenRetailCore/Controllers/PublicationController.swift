//
//  PublicationController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import ZenNIO

class PublicationController {
    
    private let repository: PublicationProtocol
    
    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as PublicationProtocol
        
        router.get("/api/publication", handler: publicationsHandlerGET)
        router.get("/api/publication/:id", handler: publicationHandlerGET)
        router.get("/api/product/:id/publication", handler: publicationProductHandlerGET)
        router.post("/api/publication", handler: publicationHandlerPOST)
        router.put("/api/publication/:id", handler: publicationHandlerPUT)
        router.delete("/api/publication/:id", handler: publicationHandlerDELETE)
    }

    func publicationsHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            let items = try self.repository.get()
            try response.send(json:items)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    func publicationHandlerGET(request: HttpRequest, response: HttpResponse) {
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

    func publicationProductHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id") else {
                throw HttpError.badRequest
            }
            let item = try self.repository.getByProduct(productId: id)
            try response.send(json:item)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func publicationHandlerPOST(request: HttpRequest, response: HttpResponse) {
        do {
            guard let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(Publication.self, from: data)
            try self.repository.add(item: item)
            try response.send(json:item)
            response.completed( .created)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    func publicationHandlerPUT(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id"),
                let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(Publication.self, from: data)
            try self.repository.update(id: id, item: item)
            try response.send(json:item)
            response.completed( .accepted)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    func publicationHandlerDELETE(request: HttpRequest, response: HttpResponse) {
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
