//
//  AngularController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 26/02/17.
//
//

import Foundation
import ZenNIO

public class AngularController {

    init(router: Router) {
        router.get("/hello") { (req, res) in
            res.send(text: "Hello world!")
            res.completed()
        }
        router.get("/", handler: angularHandler(webapi: false))
        router.get("/web", handler: angularHandler(webapi: false))
        router.get("/web/home", handler: angularHandler(webapi: false))
        router.get("/web/account", handler: angularHandler(webapi: false))
        router.get("/web/login", handler: angularHandler(webapi: false))
        router.get("/web/register", handler: angularHandler(webapi: false))
        router.get("/web/products/:id/:name", handler: angularHandler(webapi: false))
        router.get("/web/product/:id", handler: angularHandler(webapi: false))
        router.get("/web/basket", handler: angularHandler(webapi: false))
        router.get("/web/basket/:barcode", handler: angularHandler(webapi: false))
        router.get("/web/checkout", handler: angularHandler(webapi: false))
        router.get("/web/orders", handler: angularHandler(webapi: false))
        router.get("/web/document/:id", handler: angularHandler(webapi: false))
    
        router.get("/admin", handler: angularHandler())
        router.get("/admin/home", handler: angularHandler())
        router.get("/admin/company", handler: angularHandler())
        router.get("/admin/login", handler: angularHandler())
        router.get("/admin/account", handler: angularHandler())
        router.get("/admin/brand", handler: angularHandler())
        router.get("/admin/store", handler: angularHandler())
        router.get("/admin/category", handler: angularHandler())
        router.get("/admin/attribute", handler: angularHandler())
        router.get("/admin/tag", handler: angularHandler())
        router.get("/admin/product", handler: angularHandler())
        router.get("/admin/product/:id", handler: angularHandler())
        router.get("/admin/product/:id/publication", handler: angularHandler())
        router.get("/admin/product/:id/stock", handler: angularHandler())
        router.get("/admin/registry", handler: angularHandler())
        router.get("/admin/causal", handler: angularHandler())
        router.get("/admin/movement", handler: angularHandler())
        router.get("/admin/movement/:id", handler: angularHandler())
        router.get("/admin/movement/document/:id", handler: angularHandler())
        router.get("/admin/discount", handler: angularHandler())
        router.get("/admin/discount/:id", handler: angularHandler())
        router.get("/admin/invoice", handler: angularHandler())
        router.get("/admin/invoice/:id", handler: angularHandler())
        router.get("/admin/invoice/document/:id", handler: angularHandler())
        router.get("/admin/device", handler: angularHandler())
        router.get("/admin/report/receipts", handler: angularHandler())
        router.get("/admin/report/whouse", handler: angularHandler())
        router.get("/admin/report/sales", handler: angularHandler())
        router.get("/admin/report/statistics", handler: angularHandler())
        // router.get("/admin/import", handler: angularHandler())
        router.get("/admin/localization", handler: angularHandler())
        router.get("/admin/smtp", handler: angularHandler())
        router.get("/admin/shipping", handler: angularHandler())
        router.get("/admin/payment", handler: angularHandler())
        router.get("/admin/amazon", handler: angularHandler())
        router.get("/admin/cart", handler: angularHandler())
    }

    func angularHandler(webapi: Bool = true) -> HttpHandler {
        return { req, resp in
            resp.addHeader(.location, value: webapi ? "/admin/index.html" : "/web/index.html")
//            let data = FileManager.default.contents(atPath: webapi ? "./webroot/admin/index.html" : "./webroot/web/index.html")
//            guard let content = data else {
//                resp.completed( .notFound)
//                return
//            }
//
//            resp.send(html: String(data: content, encoding: .utf8)!)
            resp.completed(.found)
        }
    }
}
