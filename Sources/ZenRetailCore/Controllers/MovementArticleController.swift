//
//  MovementArticleController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

import Foundation
import ZenNIO

class MovementArticleController {
    
    private let movementRepository: MovementArticleProtocol
    private let productRepository: ProductProtocol
    
    init(router: Router) {
        self.movementRepository = ZenIoC.shared.resolve() as MovementArticleProtocol
        self.productRepository = ZenIoC.shared.resolve() as ProductProtocol

        router.get("/api/movementarticle/:id", handler: movementArticlesHandlerGET)
        router.post("/api/movementarticle/:price", handler: movementArticleHandlerPOST)
        router.put("/api/movementarticle/:id", handler: movementArticleHandlerPUT)
        router.delete("/api/movementarticle/:id", handler: movementArticleHandlerDELETE)
    }
    
    func movementArticlesHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id") else {
                throw HttpError.badRequest
            }
            let items = try self.movementRepository.get(movementId: id)
            try response.send(json:items)
            response.completed()
        } catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func movementArticleHandlerPOST(request: HttpRequest, response: HttpResponse) {
       	do {
            guard let price = request.getParam(String.self, key: "price"),
                let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(MovementArticle.self, from: data)
			try self.movementRepository.add(item: item, price: price)
            try response.send(json:item)
            response.completed( .created)
        } catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func movementArticleHandlerPUT(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id"),
                let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(MovementArticle.self, from: data)
            try self.movementRepository.update(id: id, item: item)
            try response.send(json:item)
            response.completed( .accepted)
        } catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func movementArticleHandlerDELETE(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id") else {
                throw HttpError.badRequest
            }
            try self.movementRepository.delete(id: id)
            response.completed( .noContent)
        } catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
}
