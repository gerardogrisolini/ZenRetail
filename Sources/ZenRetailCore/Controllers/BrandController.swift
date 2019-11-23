//
//  BrandController.swift
//  PerfectTurnstilePostgreSQLDemo
//
//  Created by Gerardo Grisolini on 16/02/17.
//
//

import Foundation
import ZenNIO

class BrandController {
    
    private let repository: BrandProtocol
    
    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as BrandProtocol

        router.get("/api/brand", handler: brandsHandlerGET)
        router.get("/api/brand/:id", handler: brandHandlerGET)
        router.post("/api/brand", handler: brandHandlerPOST)
        router.put("/api/brand/:id", handler: brandHandlerPUT)
        router.delete("/api/brand/:id", handler: brandHandlerDELETE)
    }

    func brandsHandlerGET(request: HttpRequest, response: HttpResponse) {
        self.repository.getAll().whenComplete { result in
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
    }
    
    func brandHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }
        
        self.repository.get(id: id).whenComplete { result in
            do {
                switch result {
                case .success(let item):
                    try response.send(json: item)
                    response.success()
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func brandHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let data = request.bodyData,
            let item = try? JSONDecoder().decode(Brand.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        self.repository.add(item: item).whenComplete { result in
            do {
                switch result {
                case .success(let id):
                    item.brandId = id
                    try response.send(json: item)
                    response.success(.created)
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func brandHandlerPUT(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id"),
            let data = request.bodyData,
            let item = try? JSONDecoder().decode(Brand.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        self.repository.update(id: id, item: item).whenComplete { result in
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
    }

    func brandHandlerDELETE(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }

        self.repository.delete(id: id).whenComplete { result in
            switch result {
            case .success(let deleted):
                response.success(deleted ? .noContent : .expectationFailed)
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }
}
