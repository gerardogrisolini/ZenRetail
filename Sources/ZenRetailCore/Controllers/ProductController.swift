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
        request.eventLoop.execute {
            do {
                let items = try self.repository.getProductTypes()
                try response.send(json:items)
                response.completed()
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func productTaxesHandlerGET(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            do {
                let items = try self.repository.getTaxes()
                try response.send(json:items)
                response.completed()
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func productsHandlerGET(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            do {
                let date: Int = request.getParam("date") ?? 0
                let items = try self.repository.getAll(date: date)
                try response.send(json:items)
                response.completed()
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func productHandlerGET(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
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
    }

    func productResetHandlerGET(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            do {
                guard let id: Int = request.getParam("id") else {
                    throw HttpError.badRequest
                }
                try self.repository.reset(id: id)
                response.completed( .noContent)
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func productBarcodeHandlerGET(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            do {
                guard let id: String = request.getParam("id") else {
                    throw HttpError.badRequest
                }
                let item = try self.repository.get(barcode: id)
                try response.send(json:item)
                response.completed()
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }
    
    func productHandlerPOST(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            do {
                guard let data = request.bodyData else {
                    throw HttpError.badRequest
                }

                let item = try JSONDecoder().decode(Product.self, from: data)
                try self.repository.add(item: item)
                let result = try self.repository.sync(item: item)
                
                try response.send(json: result)
                response.completed( .created)
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func productImportHandlerPOST(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            do {
                guard let data = request.bodyData else {
                    throw HttpError.badRequest
                }
                var item = try JSONDecoder().decode(Product.self, from: data)
                try self.repository.add(item: item)
                item = try self.repository.sync(item: item)
                let result = try self.repository.syncImport(item: item)
                try response.send(json: result)
                response.completed( .created)
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func productHandlerPUT(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            do {
                guard let id: Int = request.getParam("id"),
                    let data = request.bodyData else {
                    throw HttpError.badRequest
                }
                let item = try JSONDecoder().decode(Product.self, from: data)
                try self.repository.update(id: id, item: item)
                let result = try self.repository.sync(item: item)
                try response.send(json:result)
                response.completed( .accepted)
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
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
