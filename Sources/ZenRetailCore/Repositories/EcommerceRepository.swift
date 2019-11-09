//
//  EcommerceRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 25/10/17.
//

import Foundation
import NIO
import ZenNIO
import ZenPostgres

struct EcommerceRepository : EcommerceProtocol {

    func getSettings() -> EventLoopFuture<Setting> {
        let item = Company()
        return item.selectAsync().map { () -> Setting in
            var setting = Setting()
            setting.companyName = item.companyName
            setting.companyAddress = item.companyAddress
            setting.companyCity = item.companyCity
            setting.companyZip = item.companyZip
            setting.companyProvince = item.companyProvince
            setting.companyCountry = item.companyCountry
            setting.companyPhone = item.companyPhone
            setting.companyEmailInfo = item.companyEmailInfo
            setting.companyEmailSales = item.companyEmailSales
            setting.companyEmailSupport = item.companyEmailSupport
            setting.companyCurrency = item.companyCurrency
            setting.companyUtc = item.companyUtc
            
            setting.homeFeatured = item.homeFeatured
            setting.homeNews = item.homeNews
            setting.homeDiscount = item.homeDiscount
            setting.homeCategory = item.homeCategory
            setting.homeBrand = item.homeBrand

            setting.homeSeo = item.homeSeo
            setting.homeContent = item.homeContent
            setting.infoSeo = item.infoSeo
            setting.infoContent = item.infoContent

            setting.cashOnDelivery = item.cashOnDelivery
            setting.paypalEnv = item.paypalEnv
            setting.paypalSandbox = item.paypalSandbox
            setting.paypalProduction = item.paypalProduction
            setting.bankName = item.bankName
            setting.bankIban = item.bankIban
            
            setting.shippingStandard = item.shippingStandard
            setting.shippingExpress = item.shippingExpress
            
            return setting
        }
    }

    internal func defaultJoins() -> [DataSourceJoin] {
        return [
            DataSourceJoin(
                table: "Brand",
                onCondition: "Product.brandId = Brand.brandId",
                direction: .INNER
            ),
            DataSourceJoin(
                table: "ProductCategory",
                onCondition: "Product.productId = ProductCategory.productId",
                direction: .LEFT
            ),
            DataSourceJoin(
                table: "Category",
                onCondition: "ProductCategory.categoryId = Category.categoryId",
                direction: .INNER
            ),
            DataSourceJoin(
                table: "Publication",
                onCondition: "Product.productId = Publication.productId",
                direction: .INNER
            )
        ]
    }
    
    func getCategories() -> EventLoopFuture<[Category]> {
        let category = DataSourceJoin(
            table: "ProductCategory",
            onCondition: "Category.categoryId = ProductCategory.categoryId",
            direction: .INNER
        )
        let product = DataSourceJoin(
            table: "Product",
            onCondition: "ProductCategory.productId = Product.productId",
            direction: .INNER
        )
        let publication = DataSourceJoin(
            table: "Publication",
            onCondition: "Product.productId = Publication.productId",
            direction: .INNER
        )
        
        return Category().queryAsync(
            columns: ["DISTINCT Category.*"],
            whereclause: "Publication.publicationStartAt <= $1 AND Publication.publicationFinishAt >= $1 AND Category.categoryIsPrimary = $2 AND Product.productIsActive = $2",
            params: [Int.now(), true],
            orderby: ["Category.categoryName"],
            joins:  [category, product, publication]
        )
    }

    func getBrands() -> EventLoopFuture<[Brand]> {
        let product = DataSourceJoin(
            table: "Product",
            onCondition: "Brand.brandId = Product.brandId",
            direction: .INNER
        )
        let publication = DataSourceJoin(
            table: "Publication",
            onCondition: "Product.productId = Publication.productId",
            direction: .INNER
        )
        
        return Brand().queryAsync(
            columns: ["DISTINCT Brand.*"],
            whereclause: "Publication.publicationStartAt <= $1 AND Publication.publicationFinishAt >= $1 AND Product.productIsActive = $2",
            params: [Int.now(), true],
            orderby: ["Brand.brandName"],
            joins:  [product, publication]
        )
    }
    
    
    func getProductsFeatured() -> EventLoopFuture<[Product]> {
        let obj = Product()
        let sql = obj.querySQL(
            whereclause: "Publication.publicationFeatured = $1 AND Product.productIsActive = $1 AND Publication.publicationStartAt <= $2 AND Publication.publicationFinishAt >= $2",
            params: [true, Int.now()],
            orderby: ["Publication.publicationStartAt DESC"],
            joins: defaultJoins()
        )
        
        return obj.rowsAsync(sql: sql, barcodes: false)
    }
    
    func getProductsNews() -> EventLoopFuture<[Product]> {
        let obj = Product()
        let sql = obj.querySQL(
            whereclause: "Publication.publicationNew = $1 AND Product.productIsActive = $1 AND Publication.publicationStartAt <= $2 AND Publication.publicationFinishAt >= $2",
            params: [true, Int.now()],
            orderby: ["Publication.publicationStartAt DESC"],
            joins: defaultJoins()
        )
        
        return obj.rowsAsync(sql: sql, barcodes: false)
    }
    
    func getProductsDiscount() -> EventLoopFuture<[Product]> {
        let obj = Product()
        let now = Int.now()
        let sql = """
SELECT "Product".*, "Brand".*, "ProductCategory".*, "Category".*, "Publication".*
FROM "Product"
INNER JOIN "Brand" ON "Product"."brandId" = "Brand"."brandId"
LEFT JOIN "ProductCategory" ON "Product"."productId" = "ProductCategory"."productId"
INNER JOIN "Category" ON "ProductCategory"."categoryId" = "Category"."categoryId"
INNER JOIN "Publication" ON "Product"."productId" = "Publication"."productId"
WHERE "Product"."productIsActive" = 'true'
AND ("Product"."productDiscount" ->> 'discountStartAt')::int <= \(now)
AND ("Product"."productDiscount" ->> 'discountFinishAt')::int >= \(now)
AND "Publication"."publicationStartAt" <= \(now)
AND "Publication"."publicationFinishAt" >= \(now)
ORDER BY "Publication"."publicationStartAt" DESC
"""
        return obj.rowsAsync(sql: sql, barcodes: false)
    }

    func getProducts(brand: String) -> EventLoopFuture<[Product]> {
        let obj = Product()
        let sql = obj.querySQL(
            whereclause: "Brand.brandSeo ->> $1 = $2 AND Publication.publicationStartAt <= $3 AND Publication.publicationFinishAt >= $3 AND Product.productIsActive = $4",
            params: ["permalink", brand, Int.now(), true],
            orderby: ["Product.productName"],
            joins: defaultJoins()
        )
        
        return obj.rowsAsync(sql: sql, barcodes: false)
    }
    
    func getProducts(category: String) -> EventLoopFuture<[Product]> {
        let sql = """
SELECT "Product".*, "Brand".*, "ProductCategory".*, "Category".*, "Publication".*
FROM "Product"
INNER JOIN "Brand" ON "Product"."brandId" = "Brand"."brandId"
LEFT JOIN "ProductCategory" ON "Product"."productId" = "ProductCategory"."productId"
INNER JOIN "Category" ON "ProductCategory"."categoryId" = "Category"."categoryId"
INNER JOIN "Publication" ON "Product"."productId" = "Publication"."productId"
WHERE "Product"."productId" IN (
    SELECT DISTINCT "Product"."productId"
    FROM "Product"
    INNER JOIN "ProductCategory" ON "Product"."productId" = "ProductCategory"."productId"
    INNER JOIN "Category" ON "ProductCategory"."categoryId" = "Category"."categoryId"
    WHERE "Category"."categorySeo" ->> 'permalink' = '\(category)'
    AND "Product"."productIsActive" = true
)
AND "Publication"."publicationStartAt" <= \(Int.now())
AND "Publication"."publicationFinishAt" >= \(Int.now())
ORDER BY "Product"."productName"
"""
        return Product().rowsAsync(sql: sql, barcodes: false)
    }

    func findProducts(text: String) -> EventLoopFuture<[Product]> {
        let obj = Product()
        let sql = obj.querySQL(
            whereclause: "LOWER(Product.productName) LIKE $1 AND Publication.publicationStartAt <= $2 AND Publication.publicationFinishAt >= $2 AND Product.productIsActive = $3",
            params: ["%\(text.lowercased())%", Int.now(), true],
            joins: defaultJoins()
        )
        
        return obj.rowsAsync(sql: sql, barcodes: false)
    }

    func getProduct(name: String) -> EventLoopFuture<Product> {
        return ZenPostgres.pool.connectAsync().flatMap { conn -> EventLoopFuture<Product> in
            defer { conn.disconnect() }
            
            let item = Product(connection: conn)
            let sql = item.querySQL(
                whereclause: "Product.productSeo ->> $1 = $2",
                params: ["permalink", name],
                joins: self.defaultJoins()
            )
            
            return item.sqlRowsAsync(sql).flatMap { rows -> EventLoopFuture<Product> in
                
                let groups = Dictionary(grouping: rows) { row -> Int in
                    row.column("productId")!.int!
                }
                
                for group in groups {
                    item.decode(row: group.value.first!)
                    
                    for cat in group.value {
                        let productCategory = ProductCategory()
                        productCategory.decode(row: cat)
                        item._categories.append(productCategory)
                    }
                }
                
                return item.makeAttributesAsync().flatMap { () -> EventLoopFuture<Product> in
                    return item.makeArticlesAsync().flatMapThrowing { () -> Product in
                        if rows.count == 0 {
                            throw ZenError.recordNotFound
                        }
                        return item
                    }
                }                
            }
        }
    }

    func getBaskets() -> EventLoopFuture<[Basket]> {
        let registry = DataSourceJoin(
            table: "Registry",
            onCondition: "Basket.registryId = Registry.registryId",
            direction: .LEFT
        )
        return Basket().queryAsync(joins: [registry])
    }

    func getBasket(registryId: Int) -> EventLoopFuture<[Basket]> {
        return Basket().queryAsync(whereclause: "registryId = $1", params: [registryId])
    }
    
    func addBasket(item: Basket) -> EventLoopFuture<Basket> {
        ZenPostgres.pool.connectAsync().flatMap { conn -> EventLoopFuture<Basket> in
            defer { conn.disconnect() }

            let query: EventLoopFuture<[Basket]> = Basket(connection: conn).queryAsync(
                whereclause: "registryId = $1 AND basketBarcode = $2",
                params: [item.registryId, item.basketBarcode],
                cursor: Cursor(limit: 1, offset: 0)
            )
            
            return query.flatMap { rows -> EventLoopFuture<Basket> in
                if let current = rows.first {
                    current.connection = conn
                    current.basketQuantity += 1
                    current.basketUpdated = Int.now()
                    return current.updateAsync(
                        cols: ["basketQuantity", "basketUpdated"],
                        params: [current.basketQuantity, current.basketUpdated],
                        id: "basketId",
                        value: current.basketId
                    ).flatMapThrowing { count -> Basket in
                        item.basketId = current.basketId
                        item.basketQuantity = current.basketQuantity
                        if count > 0 {
                            return item
                        }
                        throw ZenError.recordNotSave
                    }
                } else {
                    item.basketUpdated = Int.now()
                    return item.saveAsync().flatMapThrowing { id -> Basket in
                        item.basketId = id as! Int
                        if item.basketId > 0 {
                            return item
                        }
                        throw ZenError.recordNotSave
                    }
                }
            }
        }
    }
    
    func updateBasket(id: Int, item: Basket) -> EventLoopFuture<Bool> {
        return ZenPostgres.pool.connectAsync().flatMap { conn -> EventLoopFuture<Bool> in
            defer { conn.disconnect() }

            let current = Basket(connection: conn)
            return current.getAsync(id).flatMap { rows -> EventLoopFuture<Bool> in
                current.basketQuantity = item.basketQuantity
                current.basketUpdated = Int.now()
                return current.updateAsync(
                    cols: ["basketQuantity", "basketUpdated"],
                    params: [current.basketQuantity, current.basketUpdated],
                    id: "basketId",
                    value: current.basketId
                ).flatMapThrowing { count -> Bool in
                    if current.basketId == 0 {
                        throw ZenError.recordNotFound
                    }
                    return count > 0
                }
            }
        }
    }
    
    func deleteBasket(id: Int) -> EventLoopFuture<Bool> {
        let item = Basket()
        item.basketId = id
        return item.deleteAsync()
    }
    
    func getPayments() -> [Item] {
        var items = [Item]()
        items.append(Item(id: "PayPal", value: "PayPal - Credit card"))
        items.append(Item(id: "BankTransfer", value: "Bank transfer"))
        items.append(Item(id: "CashOnDelivery", value: "Cash on delivery"))
        return items
    }

    func getShippings() -> [Item] {
        var items = [Item]()
        items.append(Item(id: "standard", value: "Standard"))
        items.append(Item(id: "express", value: "Express"))
        return items
    }

    func getShippingCost(id: String, registry: Registry) -> EventLoopFuture<Cost> {
//        var string: String
//        let data = FileManager.default.contents(atPath: "./webroot/csv/shippingcost_\(id).csv")
//        if let content = data {
//            string = String(data: content, encoding: .utf8)!
//        } else {
//            let defaultData = FileManager.default.contents(atPath: "./webroot/csv/shippingcost.csv")
//            if let defaultContent = defaultData {
//                string = String(data: defaultContent, encoding: .utf8)!
//            } else {
//                return cost
//            }
//        }
        
        return File()
            .getDataAsync(filename: "shippingcost.csv", size: .csv)
            .flatMapThrowing { bytes -> Cost in
                let string = String(bytes: bytes, encoding: .utf8)!
                let lines = string.split(separator: "\n")
                for line in lines {
                    let columns = line.split(separator: ",", omittingEmptySubsequences: false)
                    if (columns[0] == registry.registryCountry || columns[0] == "*")
                    {
                        var cost = Cost(value: 0)
                        if let value = Double(columns[4]) {
                            cost.value = value
                        }
                        if (columns[1] == registry.registryCity)
                        {
                            if let value = Double(columns[4]) {
                                cost.value = value
                            }
                            return cost
                        }
                    }
                }
                throw ZenError.recordNotFound
            }
    }

    func addOrder(registryId: Int, order: OrderModel) -> EventLoopFuture<Movement> {
        let repository = ZenIoC.shared.resolve() as MovementProtocol
        
        return ZenPostgres.pool.connectAsync().flatMapThrowing { conn -> Movement in
            defer { conn.disconnect() }

            let items: [Basket] = try Basket(connection: conn).query(whereclause: "registryId = $1", params: [registryId])
            
            if items.count == 0 {
                throw ZenError.recordNotFound
            }

            let registry = Registry(connection: conn)
            try registry.get(registryId)
            if registry.registryId == 0 {
                throw ZenError.recordNotFound
            }
            
            var store = Store(connection: conn)
            let stores: [Store] = try store.query(orderby: ["storeId"], cursor: Cursor(limit: 1, offset: 0))
            if stores.count == 1 {
                store = stores.first!
            }
            let causals: [Causal] = try Causal(connection: conn).query(
                whereclause: "causalBooked = $1 AND causalQuantity = $2 AND causalIsPos = $3",
                params: [1, -1 , true],
                orderby: ["causalId"],
                cursor: Cursor(limit: 1, offset: 0)
            )
            if causals.count == 0 {
                throw ZenError.error("no causal found")
            }
            
            let movement = Movement(connection: conn)
            movement.movementDate = Int.now()
            movement.movementStore = store
            movement.movementCausal = causals.first!
            movement.movementRegistry = registry
            movement.movementUser = "eCommerce"
            movement.movementStatus = "New"
            movement.movementPayment = order.payment
            movement.movementShipping = order.shipping
            movement.movementShippingCost = order.shippingCost
            movement.movementNote = order.paypal.isEmpty ? "" : "paypal authorization: \(order.paypal)"
            movement.movementDesc = "eCommerce order"
            
            try repository.add(item: movement)
            
            for item in items {
                let movementArticle = MovementArticle(connection: conn)
                movementArticle.movementId = movement.movementId
                movementArticle.movementArticleBarcode = item.basketBarcode
                movementArticle.movementArticleProduct = item.basketProduct
                movementArticle.movementArticlePrice = item.basketPrice
                movementArticle.movementArticleQuantity = item.basketQuantity
                movementArticle.movementArticleUpdated = Int.now()
                try movementArticle.save {
                    id in movementArticle.movementArticleId = id as! Int
                }
                try item.delete()
            }
            
            movement.movementStatus = "Processing"
            try repository.update(id: movement.movementId, item: movement)
            
            return movement
        }
    }

    func getOrders(registryId: Int) -> EventLoopFuture<[Movement]> {
        return Movement().queryAsync(whereclause: "movementRegistry ->> $1 = $2",
                                params: ["registryId", registryId],
                                orderby: ["movementId DESC"])
    }

    func getOrder(registryId: Int, id: Int) -> EventLoopFuture<Movement> {
        let query: EventLoopFuture<[Movement]> = Movement()
            .queryAsync(
                whereclause: "movementRegistry ->> $1 = $2 AND movementId = $3",
                params: ["registryId", registryId, id],
                cursor: Cursor(limit: 1, offset: 0)
            )
        return query.flatMapThrowing { rows -> Movement in
            if let row = rows.first {
                return row
            }
            throw ZenError.recordNotFound
        }

    }
    
    func getOrderItems(registryId: Int, id: Int) -> EventLoopFuture<[MovementArticle]> {
       let items = MovementArticle()
        let join = DataSourceJoin(
            table: "Movement",
            onCondition: "MovementArticle.movementId = Movement.movementId",
            direction: .RIGHT
        )
        return items.queryAsync(whereclause: "Movement.movementRegistry ->> $1 = $2 AND MovementArticle.movementId = $3",
                                params: ["registryId", registryId, id],
                                orderby: ["MovementArticle.movementArticleId"],
                                joins: [join]
        )
    }
}

