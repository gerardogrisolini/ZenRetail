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
//        router.get("/hello") { (req, res) in
//            res.send(text: "Hello world!")
//            res.completed()
//        }
//        router.get("/", handler: angularHandler(webapi: false))
//        router.get("/info", handler: angularHandler(webapi: false))
//        router.get("/login", handler: angularHandler(webapi: false))
//        router.get("/register", handler: angularHandler(webapi: false))
//        router.get("/account", handler: angularHandler(webapi: false))
//        router.get("/brand/:name", handler: angularHandler(webapi: false))
//        router.get("/category/:name", handler: angularHandler(webapi: false))
//        router.get("/product/:id", handler: angularHandler(webapi: false))
//        router.get("/basket", handler: angularHandler(webapi: false))
//        router.get("/checkout", handler: angularHandler(webapi: false))
//        router.get("/orders", handler: angularHandler(webapi: false))
//        router.get("/doc/:id", handler: angularHandler(webapi: false))
    
        router.get("/", handler: angularHandler())
        router.get("/home", handler: angularHandler())
        router.get("/company", handler: angularHandler())
        router.get("/login", handler: angularHandler())
        router.get("/account", handler: angularHandler())
        router.get("/brand", handler: angularHandler())
        router.get("/store", handler: angularHandler())
        router.get("/category", handler: angularHandler())
        router.get("/attribute", handler: angularHandler())
        router.get("/tag", handler: angularHandler())
        router.get("/product", handler: angularHandler())
        router.get("/product/:id", handler: angularHandler())
        router.get("/product/:id/publication", handler: angularHandler())
        router.get("/product/:id/stock", handler: angularHandler())
        router.get("/registry", handler: angularHandler())
        router.get("/causal", handler: angularHandler())
        router.get("/movement", handler: angularHandler())
        router.get("/movement/:id", handler: angularHandler())
        router.get("/movement/document/:id", handler: angularHandler())
        router.get("/discount", handler: angularHandler())
        router.get("/discount/:id", handler: angularHandler())
        router.get("/invoice", handler: angularHandler())
        router.get("/invoice/:id", handler: angularHandler())
        router.get("/invoice/document/:id", handler: angularHandler())
        router.get("/device", handler: angularHandler())
        router.get("/report/receipts", handler: angularHandler())
        router.get("/report/whouse", handler: angularHandler())
        router.get("/report/sales", handler: angularHandler())
        router.get("/report/statistics", handler: angularHandler())
        // router.get("/import", handler: angularHandler())
        router.get("/localization", handler: angularHandler())
        router.get("/smtp", handler: angularHandler())
        router.get("/shipping", handler: angularHandler())
        router.get("/payment", handler: angularHandler())
        router.get("/amazon", handler: angularHandler())
        router.get("/cart", handler: angularHandler())
    }

    func angularHandler(webapi: Bool = true) -> HttpHandler {
        return { req, resp in
//            resp.addHeader(.location, value: "/index.html")
//            resp.completed(.found)

            let data = FileManager.default.contents(atPath: "./webroot/index.html")
            guard let content = data else {
                resp.completed( .notFound)
                return
            }
            resp.send(html: String(data: content, encoding: .utf8)!)
            resp.completed()
        }
    }
}
