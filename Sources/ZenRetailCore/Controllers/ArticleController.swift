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
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }
        
        self.repository.build(productId: id).whenComplete { result in
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
    
    func articleGroupHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }
        
        self.repository.getGrouped(productId: id).whenComplete { result in
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
    
    func productArticleHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }
        
        self.repository.get(productId: id, storeIds: "").whenComplete { result in
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
    
    func articleStockHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id"),
            let storeIds: String = request.getParam("storeids") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameters id or storeids")
            return
        }
        
        let tagId: Int = request.getParam("tagid") ?? 0
        self.repository.getStock(productId: id, storeIds: storeIds, tagId: tagId).whenComplete { result in
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
    
    func articleHandlerGET(request: HttpRequest, response: HttpResponse) {
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
    
    func articleHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let data = request.bodyData,
            let item = try? JSONDecoder().decode(Article.self, from: data)else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id or body data")
            return
        }
        
        self.repository.addGroup(item: item).whenComplete { result in
            do {
                switch result {
                case .success(let item):
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
    
    func articleHandlerPUT(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id"), let data = request.bodyData,
            let item = try? JSONDecoder().decode(Article.self, from: data)else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id or body data")
            return
        }
        
        self.repository.update(id: id, item: item).whenComplete { result in
            do {
                switch result {
                case .success(let item):
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
    
    func articleHandlerDELETE(request: HttpRequest, response: HttpResponse) {
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
    
    func articleAttributeValueHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let data = request.bodyData,
            let item = try? JSONDecoder().decode(ArticleAttributeValue.self, from: data)else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }
        
        self.repository.addAttributeValue(item: item).whenComplete { result in
            do {
                switch result {
                case .success(let item):
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
    
    func articleAttributeValueHandlerDELETE(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }
        
        self.repository.removeAttributeValue(id: id).whenComplete { result in
            switch result {
            case .success(let deleted):
                response.completed(deleted ? .noContent : .expectationFailed)
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }
}
