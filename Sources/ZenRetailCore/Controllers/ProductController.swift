//
//  ProductController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import ZenNIO

class ProductController {
    
    private let repository: ProductProtocol
    
    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as ProductProtocol

        router.get("/api/producttype", handler: productTypesHandlerGET)
        router.get("/api/producttax", handler: productTaxesHandlerGET)
        router.get("/api/product", handler: productsHandlerGET)
        router.get("/api/productfrom/:date", handler: productsHandlerGET)
        router.get("/api/product/:id", handler: productHandlerGET)
        router.get("/api/product/barcode/:id", handler: productBarcodeHandlerGET)
		router.post("/api/product", handler: productHandlerPOST)
        router.post("/api/product/import", handler: productImportHandlerPOST)
        router.put("/api/product/:id", handler: productHandlerPUT)
        router.delete("/api/product/:id", handler: productHandlerDELETE)
        router.get("/api/product/:id/reset", handler: productResetHandlerGET)
    }
    
    func productTypesHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            try response.send(json: self.repository.getProductTypes())
            response.completed()
        } catch {
            response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    func productTaxesHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            try response.send(json: self.repository.getTaxes())
            response.completed()
        } catch {
            response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    func productsHandlerGET(request: HttpRequest, response: HttpResponse) {
        let date: Int = request.getParam("date") ?? 0
        
        self.repository.getAll(date: date).whenComplete { result in
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

    func productHandlerGET(request: HttpRequest, response: HttpResponse) {
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

    func productResetHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }

        self.repository.reset(id: id).whenComplete { result in
            switch result {
            case .success(_):
                response.completed(.noContent)
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }

    func productBarcodeHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: String = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }

        self.repository.get(barcode: id).whenComplete { result in
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
    
    func productHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let data = request.bodyData,
            let item = try? JSONDecoder().decode(Product.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        self.repository.add(item: item).whenComplete { result in
            do {
                switch result {
                case .success(let id):
                    item.productId = id
                    let result = try self.repository.sync(item: item)
                    try response.send(json: result)
                    response.completed( .created)
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func productImportHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let data = request.bodyData,
            let item = try? JSONDecoder().decode(Product.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        self.repository.add(item: item).whenComplete { result in
            do {
                switch result {
                case .success(let id):
                    item.productId = id
                    let i = try self.repository.sync(item: item)
                    let result = try self.repository.syncImport(item: i)
                    try response.send(json: result)
                    response.completed( .created)
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func productHandlerPUT(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id"),
            let data = request.bodyData,
            let item = try? JSONDecoder().decode(Product.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        self.repository.update(id: id, item: item).whenComplete { result in
            do {
                switch result {
                case .success(_):
                    let result = try self.repository.sync(item: item)
                    try response.send(json: result)
                    response.completed( .created)
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func productHandlerDELETE(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
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
}
