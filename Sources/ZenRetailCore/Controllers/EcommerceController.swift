//
//  EcommerceController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 25/10/17.
//

import Foundation
import ZenNIO
import ZenPostgres

class EcommerceController {
    
    private let repository: EcommerceProtocol
    private let registryRepository: RegistryProtocol

    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as EcommerceProtocol
        self.registryRepository = ZenIoC.shared.resolve() as RegistryProtocol

        router.get("/robots.txt") { req, res in
            let robots = """
User-agent: *
Disallow:

Sitemap: \(ZenRetail.config.serverUrl)/sitemap.xml
"""
            res.send(text: robots)
            res.success()
        }
        
        router.get("/sitemap.xml") { request, response in
            var siteMapItems = [SitemapItem]()

            func doResponse() {
                response.addHeader(.contentType, value: "application/xml; charset=utf-8")
                let data = Sitemap(items: siteMapItems).xmlString.data(using: .utf8)!
                response.send(data: data)
                response.success()
            }

            /// PAGES
            siteMapItems.append(
                SitemapItem(
                    url: "\(ZenRetail.config.serverUrl)/home",
                    changeFrequency: .daily,
                    priority: 1.0
                )
            )
            siteMapItems.append(SitemapItem(url: "\(ZenRetail.config.serverUrl)/info", priority: 0.8))
            siteMapItems.append(SitemapItem(url: "\(ZenRetail.config.serverUrl)/account", priority: 0.1))
            siteMapItems.append(SitemapItem(url: "\(ZenRetail.config.serverUrl)/login", priority: 0.1))
            siteMapItems.append(SitemapItem(url: "\(ZenRetail.config.serverUrl)/register", priority: 0.1))
            siteMapItems.append(SitemapItem(url: "\(ZenRetail.config.serverUrl)/checkout", priority: 0.1))
            siteMapItems.append(SitemapItem(url: "\(ZenRetail.config.serverUrl)/orders", priority: 0.1))
            siteMapItems.append(SitemapItem(url: "\(ZenRetail.config.serverUrl)/basket", priority: 0.1))

            /// CATEGORIES
            let cat = self.repository.getCategories()
            cat.whenSuccess { categories in
                for item in categories {
                    siteMapItems.append(
                        SitemapItem(
                            url: "\(ZenRetail.config.serverUrl)/category/\(item.categorySeo?.permalink ?? "")",
                            lastModified: Date(timeIntervalSinceReferenceDate: TimeInterval(item.categoryUpdated)),
                            changeFrequency: .weekly,
                            priority: 0.9
                        )
                    )
                }
                
                /// BRANDS
                let brand = self.repository.getBrands()
                brand.whenSuccess { brands in
                    for (i, item) in brands.enumerated() {
                        siteMapItems.append(
                            SitemapItem(
                                url: "\(ZenRetail.config.serverUrl)/brand/\(item.brandSeo.permalink)",
                                lastModified: Date(timeIntervalSinceReferenceDate: TimeInterval(item.brandUpdated)),
                                changeFrequency: .weekly,
                                priority: 0.9
                            )
                        )
                        
                        /// PRODUCTS
                        let prod = self.repository.getProducts(brand: item.brandSeo.permalink)
                        prod.whenSuccess { products in
                            for product in products {
                                siteMapItems.append(
                                    SitemapItem(
                                        url: "\(ZenRetail.config.serverUrl)/product/\(product.productSeo?.permalink ?? "")",
                                        lastModified: Date(timeIntervalSinceReferenceDate: TimeInterval(product.productUpdated)),
                                        changeFrequency: .weekly,
                                        priority: 0.9
                                    )
                                )
                            }
                            
                            if i == brands.count - 1 { doResponse() }
                        }
                        prod.whenFailure { err in
                            doResponse()
                        }
                    }
                }
                brand.whenFailure { err in
                    doResponse()
                }
            }
            cat.whenFailure { err in
                doResponse()
            }
        }
        
        /// Guest Api
        router.get("/api/ecommerce/setting", handler: ecommerceCompanyHandlerGET)
        router.get("/api/ecommerce/category", handler: ecommerceCategoriesHandlerGET)
        router.get("/api/ecommerce/brand", handler: ecommerceBrandsHandlerGET)
        router.get("/api/ecommerce/new", handler: ecommerceNewsHandlerGET)
        router.get("/api/ecommerce/sale", handler: ecommerceSaleHandlerGET)
        router.get("/api/ecommerce/featured", handler: ecommerceFeaturedHandlerGET)
        router.get("/api/ecommerce/category/:name", handler: ecommerceCategoryHandlerGET)
        router.get("/api/ecommerce/brand/:name", handler: ecommerceBrandHandlerGET)
        router.get("/api/ecommerce/product/:name", handler: ecommerceProductHandlerGET)
        router.get("/api/ecommerce/search/:text", handler: ecommerceSearchHandlerGET)

        /// Registry Api
        router.get("/api/ecommerce/registry", handler: ecommerceRegistryHandlerGET)
        router.put("/api/ecommerce/registry", handler: ecommerceRegistryHandlerPUT)
        router.delete("/api/ecommerce/registry", handler: ecommerceRegistryHandlerDELETE)

        router.get("/api/baskets", handler: ecommerceBasketsHandlerGET)
        router.get("/api/ecommerce/basket", handler: ecommerceBasketHandlerGET)
        router.post("/api/ecommerce/basket", handler: ecommerceBasketHandlerPOST)
        router.put("/api/ecommerce/basket/:id", handler: ecommerceBasketHandlerPUT)
        router.delete("/api/ecommerce/basket/:id", handler: ecommerceBasketHandlerDELETE)

        router.get("/api/ecommerce/payment", handler: ecommercePaymentsHandlerGET)
        router.get("/api/ecommerce/shipping", handler: ecommerceShippingsHandlerGET)
        router.get("/api/ecommerce/shipping/:id/cost", handler: ecommerceShippingCostHandlerGET)

        router.get("/api/ecommerce/order", handler: ecommerceOrdersHandlerGET)
        router.get("/api/ecommerce/order/:id", handler: ecommerceOrderHandlerGET)
        router.get("/api/ecommerce/order/:id/items", handler: ecommerceOrderItemsHandlerGET)
        router.post("/api/ecommerce/order", handler: ecommerceOrderHandlerPOST)

        router.post("/api/register") { request, response in
            guard let data = request.bodyData,
                let account = try? JSONDecoder().decode(Account.self, from: data) else {
                response.success(.badRequest)
                return
            }

            let promise = self.repository.register(account: account)
            promise.whenSuccess { registry in
                let session = HttpSession.new(id: request.session!.id, uniqueID: registry.uniqueID)
                request.session = session

                response.addHeader(.setCookie, value: "token=\(session.token!.bearer); expires=Sat, 01 Jan 2050 00:00:00 UTC; path=/;")
                try? response.send(json: session.token)
                response.success()
            }
            promise.whenFailure { err in
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }
    
    /// Company
    
    func ecommerceCompanyHandlerGET(request: HttpRequest, response: HttpResponse) {
        self.repository.getSettings().whenComplete { result in
            switch result {
            case .success(let items):
                try! response.send(json: items)
                response.success()
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }
    
    /// Products

    func ecommerceCategoriesHandlerGET(request: HttpRequest, response: HttpResponse) {
        self.repository.getCategories().whenComplete { result in
            switch result {
            case .success(let items):
                try! response.send(json: items)
                response.success()
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }

    func ecommerceBrandsHandlerGET(request: HttpRequest, response: HttpResponse) {
        self.repository.getBrands().whenComplete { result in
            switch result {
            case .success(let items):
                try! response.send(json: items)
                response.success()
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }

    func ecommerceNewsHandlerGET(request: HttpRequest, response: HttpResponse) {
        self.repository.getProductsNews().whenComplete { result in
            switch result {
            case .success(let items):
                try! response.send(json: items)
                response.success()
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }
    
    func ecommerceSaleHandlerGET(request: HttpRequest, response: HttpResponse) {
        self.repository.getProductsDiscount().whenComplete { result in
            switch result {
            case .success(let items):
                try! response.send(json: items)
                response.success()
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }
    
    func ecommerceFeaturedHandlerGET(request: HttpRequest, response: HttpResponse) {
        self.repository.getProductsFeatured().whenComplete { result in
            switch result {
            case .success(let items):
                try! response.send(json: items)
                response.success()
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }
    
    func ecommerceCategoryHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let name: String = request.getParam("name") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): paramenter name")
            return
        }

        self.repository.getProducts(category: name).whenComplete { result in
            switch result {
            case .success(let items):
                try! response.send(json: items)
                response.success()
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }

    func ecommerceBrandHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let name: String = request.getParam("name") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): paramenter name")
            return
        }

        self.repository.getProducts(brand: name).whenComplete { result in
            switch result {
            case .success(let items):
                try! response.send(json: items)
                response.success()
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }

    func ecommerceProductHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let name: String = request.getParam("name") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): paramenter name")
            return
        }

        self.repository.getProduct(name: name).whenComplete { result in
            switch result {
            case .success(let item):
                try! response.send(json: item)
                response.success()
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }

    func ecommerceSearchHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let text: String = request.getParam("text") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): paramenter text")
            return
        }

        self.repository.findProducts(text: text).whenComplete { result in
            switch result {
            case .success(let items):
                try! response.send(json: items)
                response.success()
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }
    
    /// Registry

    func ecommerceRegistryHandlerGET(request: HttpRequest, response: HttpResponse) {
        let uniqueID = Int(request.session?.uniqueID as? String  ?? "0")!
        
        self.registryRepository.get(id: uniqueID).whenComplete { result in
            switch result {
            case .success(let registry):
                try! response.send(json: registry)
                response.success()
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }
    
    func ecommerceRegistryHandlerPUT(request: HttpRequest, response: HttpResponse) {
        guard let uniqueID = Int(request.session?.uniqueID as! String),
            let data = request.bodyData,
            let registry = try? JSONDecoder().decode(Registry.self, from: data) else {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): paramenter text")
                return
        }

        self.registryRepository.update(id: uniqueID, item: registry).whenComplete { result in
            do {
                switch result {
                case .success(_):
                    try response.send(json: registry)
                    response.success(.accepted)
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }
    
    func ecommerceRegistryHandlerDELETE(request: HttpRequest, response: HttpResponse) {
        guard let uniqueID = Int(request.session?.uniqueID as! String) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }

        self.registryRepository.delete(id: uniqueID).whenComplete { result in
            switch result {
            case .success(let deleted):
                response.success(deleted ? .noContent : .expectationFailed)
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }
    
    /// Basket

    func ecommerceBasketsHandlerGET(request: HttpRequest, response: HttpResponse) {
        self.repository.getBaskets().whenComplete { result in
            switch result {
            case .success(let items):
                try! response.send(json: items)
                response.success()
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }

    func ecommerceBasketHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let uniqueID = request.session?.uniqueID as? String , let id = Int(uniqueID) else {
            return response.failure(.unauthorized)
        }

        self.repository.getBasket(registryId: id).whenComplete { result in
            switch result {
            case .success(let items):
                try! response.send(json: items)
                response.success()
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }
    
    func ecommerceBasketHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let uniqueID = request.session?.uniqueID as? String , let id = Int(uniqueID) else {
            return response.failure(.unauthorized)
        }

        guard let data = request.bodyData,
            let basket = try? JSONDecoder().decode(Basket.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        basket.registryId = id
        
        let product = Product()
        product.get(barcode: basket.basketBarcode).whenComplete { result in
            switch result {
            case .success(_):
                if product.productId == 0 {
                    response.success(.notFound)
                    return
                }
                basket.basketProduct = product
                basket.basketPrice = product.productDiscount != nil
                    ? product.productDiscount!.discountPrice : product.productPrice.selling

                self.repository.addBasket(item: basket).whenComplete { res in
                    switch res {
                    case .success(let item):
                        try! response.send(json: item)
                        response.success(.created)
                    case .failure(let err):
                        response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
                    }
                }
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }
    
    func ecommerceBasketHandlerPUT(request: HttpRequest, response: HttpResponse) {
       guard let id: Int = request.getParam("id"),
            let data = request.bodyData,
            let basket = try? JSONDecoder().decode(Basket.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
       }
        
       self.repository.updateBasket(id: id, item: basket).whenComplete { res in
           switch res {
           case .success(let result):
               try! response.send(json: basket)
               response.success(result ? .accepted : .notModified)
           case .failure(let err):
               response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
           }
        }
    }
    
    func ecommerceBasketHandlerDELETE(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
             response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
             return
        }

        self.repository.deleteBasket(id: id).whenComplete { res in
            switch res {
            case .success(let result):
                response.success(result ? .noContent : .notModified)
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }

    /// Payment
    
    func ecommercePaymentsHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            let items = self.repository.getPayments()
            try response.send(json:items)
            response.success()
        } catch {
            response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    /// Shipping
    
    func ecommerceShippingsHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            let items = self.repository.getShippings()
            try response.send(json:items)
            response.success()
        } catch {
            response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    func ecommerceShippingCostHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: String = request.getParam("id"),
            let uniqueID = Int(request.session?.uniqueID as! String) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }
                
        self.registryRepository.get(id: uniqueID).whenComplete { result in
           switch result {
           case .success(let registry):
               self.repository.getShippingCost(id: id, registry: registry).whenComplete { res in
                   switch res {
                   case .success(let cost):
                       try? response.send(json: cost)
                       response.success()
                   case .failure(let err):
                       response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
                   }
               }
           case .failure(let err):
               response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
           }
        }
    }

    /// Order
    
    func ecommerceOrdersHandlerGET(request: HttpRequest, response: HttpResponse) {
        let uniqueID = Int(request.session?.uniqueID as? String  ?? "0")!
        self.repository.getOrders(registryId: uniqueID).whenComplete { res in
            switch res {
            case .success(let items):
                try! response.send(json: items)
                response.success()
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }
    
    func ecommerceOrderHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }

        let uniqueID = Int(request.session?.uniqueID as? String  ?? "0")!
        self.repository.getOrder(registryId: uniqueID, id: id).whenComplete { res in
            switch res {
            case .success(let item):
                try! response.send(json: item)
                response.success()
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }

    func ecommerceOrderItemsHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let id: Int = request.getParam("id") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter id")
            return
        }

        let uniqueID = Int(request.session?.uniqueID as? String  ?? "0")!
        self.repository.getOrderItems(registryId: uniqueID, id: id).whenComplete { res in
            switch res {
            case .success(let items):
                try! response.send(json: items)
                response.success()
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }

    func ecommerceOrderHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let data = request.bodyData,
            let order = try? JSONDecoder().decode(OrderModel.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }

        let uniqueID = Int(request.session?.uniqueID as? String  ?? "0")!
        self.repository.addOrder(registryId: uniqueID, order: order).whenComplete { res in
            switch res {
            case .success(let item):
                try! response.send(json: item)
                response.success()
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }
}

