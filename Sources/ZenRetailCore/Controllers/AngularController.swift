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

    private let repository: EcommerceProtocol

    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as EcommerceProtocol

        router.get("/", handler: angularHandler(webapi: false))
        router.get("/home", handler: angularHandler(webapi: false))
        router.get("/info", handler: angularHandler(webapi: false))
        router.get("/login", handler: angularHandler(webapi: false))
        router.get("/register", handler: angularHandler(webapi: false))
        router.get("/account", handler: angularHandler(webapi: false))
        router.get("/brand/:name", handler: angularHandler(webapi: false))
        router.get("/category/:name", handler: angularHandler(webapi: false))
        router.get("/product/:name", handler: angularHandler(webapi: false))
        router.get("/basket", handler: angularHandler(webapi: false))
        router.get("/checkout", handler: angularHandler(webapi: false))
        router.get("/orders", handler: angularHandler(webapi: false))
        router.get("/doc/:id", handler: angularHandler(webapi: false))
    
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
            var data: Data?
            
            if let agent = req.head.headers["User-Agent"].first?.lowercased(),
                agent.contains("googlebot") || agent.contains("adsbot")
                || agent.contains("bingbot") || agent.contains("msnbot") {
                data = self.getContent(request: req)
            } else {
                data = FileManager.default.contents(atPath: webapi ? "./webroot/admin/index.html" : "./webroot/index.html")
            }
            
            guard let content = data else {
                resp.completed( .notFound)
                return
            }
            resp.addHeader(.contentType, value: "text/html")
            resp.send(data: content)
            resp.completed()
        }
    }
    
    func getContent(request: HttpRequest) -> Data? {
        do {
            var content = try self.getHtml()
            let settings = try self.repository.getSettings()
            content = content
                .replacingOccurrences(of: "#sitename#", with: settings.companyName)
                .replacingOccurrences(of: "#url#", with: "\(ZenRetail.config.serverUrl)\(request.head.uri)")

            switch request.head.uri {
            case let x where x.hasPrefix("/brand"):
                guard let name = request.getParam(String.self, key: "name") else {
                    return nil
                }
                let products = try self.repository.getProducts(brand: name)
                guard let brand = products.first?._brand else {
                    return nil
                }
                content = content
                    .replacingOccurrences(of: "#robots#", with: "index, follow")
                    .replacingOccurrences(of: "#title#", with: brand.brandSeo.title.defaultValue())
                    .replacingOccurrences(of: "#description#", with: brand.brandSeo.description.defaultValue())
                    .replacingOccurrences(of: "#content#", with: brand.brandDescription.defaultValue())
                    .replacingOccurrences(of: "#image#", with: "\(ZenRetail.config.serverUrl)/media/\(brand.brandMedia.name)")
                break
            case let x where x.hasPrefix("/category"):
                guard let name = request.getParam(String.self, key: "name") else {
                    return nil
                }
                let products = try self.repository.getProducts(category: name)
                guard let category = products.first?._categories.first(where: { $0._category.categorySeo.permalink == name })?._category else {
                    return nil
                }
                content = content
                    .replacingOccurrences(of: "#robots#", with: "index, follow")
                    .replacingOccurrences(of: "#title#", with: category.categorySeo.title.defaultValue())
                    .replacingOccurrences(of: "#description#", with: category.categorySeo.description.defaultValue())
                    .replacingOccurrences(of: "#content#", with: category.categoryDescription.defaultValue())
                    .replacingOccurrences(of: "#image#", with: "\(ZenRetail.config.serverUrl)/media/\(category.categoryMedia.name)")
                break
            case let x where x.hasPrefix("/product"):
                guard let name = request.getParam(String.self, key: "name") else {
                    return nil
                }
                let product = try self.repository.getProduct(name: name)
                let info = """
<h1>\(product.productName)</h1>
<p>\(product.productDescription.defaultValue())</p>
<p>Category: <b>\(product._categories.map { $0._category.categoryDescription.defaultValue() }.joined(separator: "</b>, <b>"))</b></p>
<p>Price: <b>\(product.productPrice.selling.formatCurrency())</b></p>
<p><img src="/thumb/\(product.productMedia.first?.name ?? "logo.png")" alt='\(product.productName)'></p>
"""
                content = content
                    .replacingOccurrences(of: "#robots#", with: "index, follow")
                    .replacingOccurrences(of: "#title#", with: product.productSeo.title.defaultValue())
                    .replacingOccurrences(of: "#description#", with: product.productSeo.description.defaultValue())
                    .replacingOccurrences(of: "#content#", with: info)
                    .replacingOccurrences(of: "#image#", with: "\(ZenRetail.config.serverUrl)/media/\(product.productMedia.first?.name ?? "")")
                break
            case let x where x.hasPrefix("/info"):
                content = content
                    .replacingOccurrences(of: "#robots#", with: "index, follow")
                    .replacingOccurrences(of: "#title#", with: settings.companyInfoSeo.title.defaultValue())
                    .replacingOccurrences(of: "#description#", with: settings.companyInfoSeo.description.defaultValue())
                    .replacingOccurrences(of: "#content#", with: settings.companyInfoContent.defaultValue())
                    .replacingOccurrences(of: "#image#", with: "\(ZenRetail.config.serverUrl)/media/logo.png")
                break
            case let x where x.hasPrefix("/home"):
                content = content
                    .replacingOccurrences(of: "#robots#", with: "index, follow")
                    .replacingOccurrences(of: "#title#", with: settings.companyHomeSeo.title.defaultValue())
                    .replacingOccurrences(of: "#description#", with: settings.companyHomeSeo.description.defaultValue())
                    .replacingOccurrences(of: "#content#", with: settings.companyHomeContent.defaultValue())
                    .replacingOccurrences(of: "#image#", with: "\(ZenRetail.config.serverUrl)/media/logo.png")
                break
            default:
                content = content
                    .replacingOccurrences(of: "#robots#", with: "noindex")
                    .replacingOccurrences(of: "#title#", with: settings.companyName)
                    .replacingOccurrences(of: "#description#", with: "")
                    .replacingOccurrences(of: "#content#", with: "")
                    .replacingOccurrences(of: "#image#", with: "")
                break
            }
            
            return content.data(using: .utf8)
        } catch {
            print(error)
            return nil
        }
    }
    
    func getHtml() throws -> String {
        let content = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <base href="/">
    <title>#title#</title>
    <link rel="canonical" href="#url#">
    <meta name="description" content="#description#">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="viewport" content="initial-scale=1,minimum-scale=1,maximum-scale=1,user-scalable=no">
    <meta name="robots" content="#robots#">
    <meta property="og:title" content="#title#">
    <meta property="og:description" content="#description#">
    <meta property="og:type" content="website">
    <meta property="og:url" content="#url#">
    <meta property="og:image" content="#image#">
    <meta property="og:site_name" content="#sitename#">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:site" content="#sitename#">
    <meta name="twitter:title" content="#title#">
    <meta name="twitter:description" content="#description#">
    <meta name="twitter:image" content="#image#">
</head>
<body>
#content#
</body>
</html>
"""
        return content
    }
}
