//
//  MovementArticleController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

import Foundation
import ZenNIO
import ZenPostgres

class MovementArticleController {
    
    private let repository: MovementArticleProtocol
    
    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as MovementArticleProtocol

        router.get("/api/movementarticle/:id", handler: movementArticlesHandlerGET)
        router.post("/api/movementarticle/:price", handler: movementArticleHandlerPOST)
        router.put("/api/movementarticle/:id", handler: movementArticleHandlerPUT)
        router.delete("/api/movementarticle/:id", handler: movementArticleHandlerDELETE)
    }
    
    func movementArticlesHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }
        
        ZenPostgres.pool.connect().whenComplete { res in
            switch res {
            case .success(let conn):
                defer { conn.disconnect() }
                
                self.repository.get(movementId: id, connection: conn).whenComplete { result in
                    do {
                        switch result {
                        case .success(let items):
                            try response.send(json: items)
                            response.success()
                        case .failure(let err):
                            throw err
                        }
                    } catch {
                        response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
                    }
                }
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }
    
    func movementArticleHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let price: String = request.getParam("price"),
            let data = request.bodyData,
            let item = try? JSONDecoder().decode(MovementArticle.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        ZenPostgres.pool.connect().whenComplete { res in
            switch res {
            case .success(let conn):
                defer { conn.disconnect() }
                
                self.repository.add(item: item, price: price, connection: conn).whenComplete { result in
                    do {
                        switch result {
                        case .success(let id):
                            item.movementId = id
                            try response.send(json: item)
                            response.success(.created)
                        case .failure(let err):
                            throw err
                        }
                    } catch {
                        response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
                    }
                }
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }
    
    func movementArticleHandlerPUT(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id"),
            let data = request.bodyData,
            let item = try? JSONDecoder().decode(MovementArticle.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        ZenPostgres.pool.connect().whenComplete { res in
            switch res {
            case .success(let conn):
                defer { conn.disconnect() }
                
                self.repository.update(id: id, item: item, connection: conn).whenComplete { result in
                    do {
                        switch result {
                        case .success(_):
                            try response.send(json: item)
                            response.success(.accepted)
                        case .failure(let err):
                            throw err
                        }
                    } catch {
                        response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
                    }
                }
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }
    
    func movementArticleHandlerDELETE(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }

        ZenPostgres.pool.connect().whenComplete { res in
            switch res {
            case .success(let conn):
                defer { conn.disconnect() }
                
                self.repository.delete(id: id, connection: conn).whenComplete { result in
                    switch result {
                    case .success(let deleted):
                        response.success(deleted ? .noContent : .expectationFailed)
                    case .failure(let err):
                        response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
                    }
                }
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }
}
