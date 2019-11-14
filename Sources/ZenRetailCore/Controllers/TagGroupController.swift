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
        self.repository.getAll().whenComplete { result in
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
    
    func tagAllHandlerGET(request: HttpRequest, response: HttpResponse) {
        self.repository.getAllAndValues().whenComplete { result in
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

    func tagHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: String = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }
        
        if id == "all" {
            self.repository.getAllAndValues().whenComplete { result in
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
        } else {
            self.repository.get(id: Int(id)!).whenComplete { result in
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
    }
    
    func tagValueHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }
        
        self.repository.getValues(id: id).whenComplete { result in
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
    
    func tagHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let data = request.bodyData,
            let item = try? JSONDecoder().decode(TagGroup.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        self.repository.add(item: item).whenComplete { result in
            do {
                switch result {
                case .success(let id):
                    item.tagGroupId = id
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
    
    func tagHandlerPUT(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id"),
            let data = request.bodyData,
            let item = try? JSONDecoder().decode(TagGroup.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        self.repository.update(id: id, item: item).whenComplete { result in
            do {
                switch result {
                case .success(_):
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
    
    func tagHandlerDELETE(request: HttpRequest, response: HttpResponse) {
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
}

