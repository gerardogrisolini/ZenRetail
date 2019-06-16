//
//  ArticleController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import ZenNIO

class ArticleController {
    
    private let repository: ArticleProtocol
    
    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as ArticleProtocol

        router.get("/api/product/:id/build", handler: articleBuildHandlerGET)
        router.get("/api/product/:id/article", handler: productArticleHandlerGET)
        router.get("/api/product/:id/group", handler: articleGroupHandlerGET)
        router.get("/api/product/:id/store/:storeids", handler: articleStockHandlerGET)
        router.get("/api/product/:id/store/:storeids/:tagid", handler: articleStockHandlerGET)

        router.post("/api/article", handler: articleHandlerPOST)
        router.get("/api/article/:id", handler: articleHandlerGET)
        router.put("/api/article/:id", handler: articleHandlerPUT)
        router.delete("/api/article/:id", handler: articleHandlerDELETE)
        router.post("/api/articleattributevalue", handler: articleAttributeValueHandlerPOST)
        router.delete("/api/articleattributevalue/:id", handler: articleAttributeValueHandlerDELETE)
    }
    
    func articleBuildHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id") else {
                throw HttpError.badRequest
            }
            let result = try self.repository.build(productId: id)
            try response.send(json: result)
            response.completed()
        } catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func articleGroupHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id") else {
                throw HttpError.badRequest
            }
            let items = try self.repository.getGrouped(productId: id)
            try response.send(json: items)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func productArticleHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id") else {
                throw HttpError.badRequest
            }
            let item = try self.repository.get(productId: id, storeIds: "0")
            try response.send(json: item)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func articleStockHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id"),
                let storeIds = request.getParam(String.self, key: "storeids") else {
                throw HttpError.badRequest
            }
            let tagId = request.getParam(Int.self, key: "tagid") ?? 0
            let item = try self.repository.getStock(productId: id, storeIds: storeIds, tagId: tagId)
            try response.send(json: item)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func articleHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id") else {
                throw HttpError.badRequest
            }
            if let item = self.repository.get(id: id) {
                try response.send(json: item)
                response.completed()
            } else {
                response.completed(.notFound)
            }
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func articleHandlerPOST(request: HttpRequest, response: HttpResponse) {
        do {
            guard let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(Article.self, from: data)
            let group = try self.repository.addGroup(item: item)
            try response.send(json: group)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func articleHandlerPUT(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id"), let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(Article.self, from: data)
            try self.repository.update(id: id, item: item)
            try response.send(json: item)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func articleHandlerDELETE(request: HttpRequest, response: HttpResponse) {
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
    
    func articleAttributeValueHandlerPOST(request: HttpRequest, response: HttpResponse) {
        do {
            guard let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(ArticleAttributeValue.self, from: data)
            try self.repository.addAttributeValue(item: item)
            try response.send(json: item)
            response.completed(.created)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func articleAttributeValueHandlerDELETE(request: HttpRequest, response: HttpResponse) {
        do {
            guard let id = request.getParam(Int.self, key: "id") else {
                throw HttpError.badRequest
            }
            try self.repository.removeAttributeValue(id: id)
            response.completed(.noContent)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
}
