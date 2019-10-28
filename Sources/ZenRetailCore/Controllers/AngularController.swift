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
            req.eventLoop.execute {
                var data: Data?
                
                let header = ZenNIO.http == .v1 ? "User-Agent" : "user-agent";
                if let agent = req.head.headers[header].first?.lowercased(),
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
    }
    
    func getContent(request: HttpRequest) -> Data? {
        var country = "EN"
        let header = ZenNIO.http == .v1 ? "Accept-Language" : "accept-language";
        if let language = request.head.headers[header].first {
            country = language[...language.index(language.startIndex, offsetBy: 1)].uppercased()
        }
        
        do {
            var content = try getHtml()
            let settings = try repository.getSettings()
            content = content
                .replacingOccurrences(of: "#sitename#", with: settings.companyName)
                .replacingOccurrences(of: "#url#", with: "\(ZenRetail.config.serverUrl)\(request.head.uri)")

            switch request.head.uri {
            case let x where x.hasPrefix("/brand"):
                guard let name: String = request.getParam("name") else {
                    return nil
                }
                let products = try repository.getProducts(brand: name)
                guard let brand = products.first?._brand else {
                    return nil
                }

                var body = "<h1>\(brand.brandDescription.valueOrDefault(country: country))</h1>"
                body += "<br/><ul>"
                for item in products {
                    body += getProductHtml(item: item, country: country)
                }
                body += "</ul>"

                content = content
                    .replacingOccurrences(of: "#robots#", with: "index, follow")
                    .replacingOccurrences(of: "#title#", with: brand.brandSeo.title.valueOrDefault(country: country))
                    .replacingOccurrences(of: "#description#", with: brand.brandSeo.description.valueOrDefault(country: country))
                    .replacingOccurrences(of: "#content#", with: body)
                    .replacingOccurrences(of: "#image#", with: "\(ZenRetail.config.serverUrl)/thumb/\(brand.brandMedia.name)")
                break
            case let x where x.hasPrefix("/category"):
                guard let name: String = request.getParam("name") else {
                    return nil
                }
                let products = try repository.getProducts(category: name)
                guard let category = products.first?._categories.first(where: { $0._category.categorySeo?.permalink == name })?._category else {
                    return nil
                }

                var body = "<h1>\(category.categoryDescription.valueOrDefault(country: country))</h1>"
                body += "<br/><ul>"
                for item in products {
                    body += getProductHtml(item: item, country: country)
                }
                body += "</ul>"

                content = content
                    .replacingOccurrences(of: "#robots#", with: "index, follow")
                    .replacingOccurrences(of: "#title#", with: category.categorySeo?.title.valueOrDefault(country: country) ?? category.categoryName)
                    .replacingOccurrences(of: "#description#", with: category.categorySeo?.description.valueOrDefault(country: country) ?? "")
                    .replacingOccurrences(of: "#content#", with: body)
                    .replacingOccurrences(of: "#image#", with: "\(ZenRetail.config.serverUrl)/thumb/\(category.categoryMedia?.name ?? "logo.png")")
                break
            case let x where x.hasPrefix("/product"):
                guard let name: String = request.getParam("name") else {
                    return nil
                }
                let product = try repository.getProduct(name: name)
                var body = """
<h1>\(product.productName)</h1>
<p>\(product._categories.map { $0._category.categoryDescription.valueOrDefault(country: country) }.joined(separator: " - "))</p>
<p>\(product.productDescription.valueOrDefault(country: country))</p>
<p>\(product.productPrice.selling.formatCurrency())</p>
"""
                for media in product.productMedia {
                    body += """
<p><img src="/thumb/\(media.name)" alt='\(product.productName)'></p>
"""
                }

                for att in product._attributes {
                    body += "<ul> <b>\(att._attribute.attributeTranslates.valueOrDefault(country: country, defaultValue: att._attribute.attributeName).uppercased())</b>"
                    for val in att._attributeValues {
                        body += "<li>\(val._attributeValue.attributeValueTranslates.valueOrDefault(country: country, defaultValue: val._attributeValue.attributeValueName))</li>"
                    }
                    body += "</ul>"
                }

                content = content
                    .replacingOccurrences(of: "#robots#", with: "index, follow")
                    .replacingOccurrences(of: "#title#", with: product.productSeo?.title.valueOrDefault(country: country) ?? product.productName)
                    .replacingOccurrences(of: "#description#", with: product.productSeo?.description.valueOrDefault(country: country) ?? "")
                    .replacingOccurrences(of: "#content#", with: body)
                    .replacingOccurrences(of: "#image#", with: "\(ZenRetail.config.serverUrl)/thumb/\(product.productMedia.first?.name ?? "")")
                break
            case let x where x.hasPrefix("/info"):
                content = content
                    .replacingOccurrences(of: "#robots#", with: "index, follow")
                    .replacingOccurrences(of: "#title#", with: settings.infoSeo.title.valueOrDefault(country: country))
                    .replacingOccurrences(of: "#description#", with: settings.infoSeo.description.valueOrDefault(country: country))
                    .replacingOccurrences(of: "#content#", with: settings.infoContent.valueOrDefault(country: country))
                    .replacingOccurrences(of: "#image#", with: "\(ZenRetail.config.serverUrl)/thumb/logo.png")
                break
            case let x where x.hasPrefix("/home") || x.hasPrefix("/"):
                var body = settings.homeContent.valueOrDefault(country: country)
                if settings.homeFeatured {
                    let featured = try repository.getProductsFeatured()
                    body += "<br/><ul><h3>Featured</h3>"
                    for item in featured {
                        body += getProductHtml(item: item, country: country)
                    }
                    body += "</ul>"
                }
                if settings.homeNews {
                    let news = try repository.getProductsNews()
                    body += "<br/><ul><h3>News</h3>"
                    for item in news {
                        body += getProductHtml(item: item, country: country)
                    }
                    body += "</ul>"
                }
//                if settings.homeDiscount {
//                    let discount = try repository.getProductsDiscount()
//                    body += "<br/><ul><h3>Discount</h3>"
//                    for item in discount {
//                        body += getProductHtml(item: item, country: country)
//                    }
//                    body += "</ul>"
//                }
                if settings.homeCategory {
                    let categories = try repository.getCategories()
                    body += "<br/><ul><h3>Categories</h3>"
                    for item in categories {
                        body += """
<li>
    <a href="/category/\(item.categorySeo?.permalink ?? "")">
        <h4>\(item.categoryDescription.valueOrDefault(country: country))</h4>
    </a>
    <p><img src="/thumb/\(item.categoryMedia?.name ?? "logo.png")" alt='\(item.categoryName)'></p>
</li>
"""
                    }
                    body += "</ul>"
                }
                if settings.homeBrand {
                    let brands = try repository.getBrands()
                    body += "<br/><ul><h3>Brands</h3>"
                    for item in brands {
                        body += """
<li>
    <a href="/brand/\(item.brandSeo.permalink)">
        <h4>\(item.brandDescription.valueOrDefault(country: country))</h4>
    </a>
    <p><img src="/thumb/\(item.brandMedia.name)" alt='\(item.brandName)'></p>
</li>
"""
                    }
                    body += "</ul>"
                }
                
                content = content
                    .replacingOccurrences(of: "#robots#", with: "index, follow")
                    .replacingOccurrences(of: "#title#", with: settings.homeSeo.title.valueOrDefault(country: country))
                    .replacingOccurrences(of: "#description#", with: settings.homeSeo.description.valueOrDefault(country: country))
                    .replacingOccurrences(of: "#content#", with: body)
                    .replacingOccurrences(of: "#image#", with: "\(ZenRetail.config.serverUrl)/thumb/logo.png")
                break
            default:
                return nil
            }
            
            return content.data(using: .utf8)
        } catch {
            print(error)
            return nil
        }
    }
    
    private func getProductHtml(item: Product, country: String) -> String {
        return """
<li>
    <a href="/product/\(item.productSeo?.permalink ?? "")"><h4>\(item.productName)</h4></a>
    <p>\(item._categories.map { $0._category.categoryDescription.valueOrDefault(country: country) }.joined(separator: " - "))</p>
    <p>\(item.productDescription.valueOrDefault(country: country))</p>
    <p>\(item.productPrice.selling.formatCurrency())</p>
    <p><img src="/thumb/\(item.productMedia.first?.name ?? "logo.png")" alt='\(item.productName)'></p>
</li>
"""
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
