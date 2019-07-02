//
//  CategoryController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import ZenNIO

class CategoryController {
    
    private let repository: CategoryProtocol
    
    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as CategoryProtocol

        router.get("/api/category", handler: categoriesHandlerGET)
        router.get("/api/category/:id", handler: categoryHandlerGET)
        router.post("/api/category", handler: categoryHandlerPOST)
        router.put("/api/category/:id", handler: categoryHandlerPUT)
        router.delete("/api/category/:id", handler: categoryHandlerDELETE)
    }

    func categoriesHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            let items = try self.repository.getAll()
            try response.send(json:items)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func categoryHandlerGET(request: HttpRequest, response: HttpResponse) {
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

    func categoryHandlerPOST(request: HttpRequest, response: HttpResponse) {
        do {
            guard let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(Category.self, from: data)
            try self.repository.add(item: item)
            try response.send(json:item)
            response.completed( .created)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    func categoryHandlerPUT(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id: Int = request.getParam("id"),
                let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(Category.self, from: data)
            try self.repository.update(id: id, item: item)
            try response.send(json:item)
            response.completed( .accepted)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    func categoryHandlerDELETE(request: HttpRequest, response: HttpResponse) {
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
