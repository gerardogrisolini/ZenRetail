//
//  AngularController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 26/02/17.
//
//

import ZenNIO

public class AngularController {

    init(router: Router) {
        router.get("/", handler: ZenRetail.angularHandler(webapi: false))
        router.get("/web", handler: ZenRetail.angularHandler(webapi: false))
        router.get("/web/home", handler: ZenRetail.angularHandler(webapi: false))
        router.get("/web/account", handler: ZenRetail.angularHandler(webapi: false))
        router.get("/web/login", handler: ZenRetail.angularHandler(webapi: false))
        router.get("/web/register", handler: ZenRetail.angularHandler(webapi: false))
        router.get("/web/products/:id/:name", handler: ZenRetail.angularHandler(webapi: false))
        router.get("/web/product/:id", handler: ZenRetail.angularHandler(webapi: false))
        router.get("/web/basket", handler: ZenRetail.angularHandler(webapi: false))
        router.get("/web/basket/:barcode", handler: ZenRetail.angularHandler(webapi: false))
        router.get("/web/checkout", handler: ZenRetail.angularHandler(webapi: false))
        router.get("/web/orders", handler: ZenRetail.angularHandler(webapi: false))
        router.get("/web/document/:id", handler: ZenRetail.angularHandler(webapi: false))
    
        router.get("/admin", handler: ZenRetail.angularHandler())
        router.get("/admin/home", handler: ZenRetail.angularHandler())
        router.get("/admin/company", handler: ZenRetail.angularHandler())
        router.get("/admin/login", handler: ZenRetail.angularHandler())
        router.get("/admin/account", handler: ZenRetail.angularHandler())
        router.get("/admin/brand", handler: ZenRetail.angularHandler())
        router.get("/admin/store", handler: ZenRetail.angularHandler())
        router.get("/admin/category", handler: ZenRetail.angularHandler())
        router.get("/admin/attribute", handler: ZenRetail.angularHandler())
        router.get("/admin/tag", handler: ZenRetail.angularHandler())
        router.get("/admin/product", handler: ZenRetail.angularHandler())
        router.get("/admin/product/:id", handler: ZenRetail.angularHandler())
        router.get("/admin/product/:id/publication", handler: ZenRetail.angularHandler())
        router.get("/admin/product/:id/stock", handler: ZenRetail.angularHandler())
        router.get("/admin/registry", handler: ZenRetail.angularHandler())
        router.get("/admin/causal", handler: ZenRetail.angularHandler())
        router.get("/admin/movement", handler: ZenRetail.angularHandler())
        router.get("/admin/movement/:id", handler: ZenRetail.angularHandler())
        router.get("/admin/movement/document/:id", handler: ZenRetail.angularHandler())
        router.get("/admin/discount", handler: ZenRetail.angularHandler())
        router.get("/admin/discount/:id", handler: ZenRetail.angularHandler())
        router.get("/admin/invoice", handler: ZenRetail.angularHandler())
        router.get("/admin/invoice/:id", handler: ZenRetail.angularHandler())
        router.get("/admin/invoice/document/:id", handler: ZenRetail.angularHandler())
        router.get("/admin/device", handler: ZenRetail.angularHandler())
        router.get("/admin/report/receipts", handler: ZenRetail.angularHandler())
        router.get("/admin/report/whouse", handler: ZenRetail.angularHandler())
        router.get("/admin/report/sales", handler: ZenRetail.angularHandler())
        router.get("/admin/report/statistics", handler: ZenRetail.angularHandler())
        // router.get("/admin/import", handler: ZenRetail.angularHandler())
        router.get("/admin/localization", handler: ZenRetail.angularHandler())
        router.get("/admin/smtp", handler: ZenRetail.angularHandler())
        router.get("/admin/shipping", handler: ZenRetail.angularHandler())
        router.get("/admin/payment", handler: ZenRetail.angularHandler())
        router.get("/admin/amazon", handler: ZenRetail.angularHandler())
        router.get("/admin/cart", handler: ZenRetail.angularHandler())
    }
}
