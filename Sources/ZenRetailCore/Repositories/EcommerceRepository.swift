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
        let promise: EventLoopPromise<Setting> = ZenPostgres.pool.newPromise()
        
        let item = Company()
        let query = item.selectAsync()
        query.whenSuccess { _ in
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
            
            promise.succeed(setting)
        }
        query.whenFailure { err in
            promise.fail(err)
        }
        
        return promise.futureResult
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
        let promise: EventLoopPromise<Product> = ZenPostgres.pool.newPromise()

        let connect = ZenPostgres.pool.connectAsync()
        connect.whenSuccess { conn in
            defer { conn.disconnect() }
            
            let item = Product(connection: conn)
            let sql = item.querySQL(
                whereclause: "Product.productSeo ->> $1 = $2",
                params: ["permalink", name],
                joins: self.defaultJoins()
            )
            
            let query = item.sqlRowsAsync(sql)
            query.whenSuccess { rows in
                if rows.count == 0 {
                    promise.fail(ZenError.recordNotFound)
                    return
                }
                
                let groups = rows.groupBy { row -> Int in
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
                
                item.makeAttributesAsync().whenComplete { _ in
                    item.makeArticlesAsync().whenComplete { _ in
                        promise.succeed(item)
                    }
                }                
            }
            query.whenFailure { err in
                promise.fail(err)
            }
        }
        connect.whenFailure { err in
            promise.fail(err)
        }

        return promise.futureResult
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
        let promise: EventLoopPromise<Basket> = ZenPostgres.pool.newPromise()
        
        let connect = ZenPostgres.pool.connectAsync()
        connect.whenSuccess { conn in
            defer { conn.disconnect() }

            let query: EventLoopFuture<[Basket]> = Basket(connection: conn).queryAsync(
                whereclause: "registryId = $1 AND basketBarcode = $2",
                params: [item.registryId, item.basketBarcode],
                cursor: Cursor(limit: 1, offset: 0)
            )
            
            query.whenSuccess { rows in
                if let current = rows.first {
                    current.connection = conn
                    current.basketQuantity += 1
                    current.basketUpdated = Int.now()
                    current.updateAsync(
                        cols: ["basketQuantity", "basketUpdated"],
                        params: [current.basketQuantity, current.basketUpdated],
                        id: "basketId",
                        value: current.basketId
                    ).whenComplete { result in
                        switch result {
                        case .success(let count):
                            item.basketId = current.basketId
                            item.basketQuantity = current.basketQuantity
                            if count > 0 {
                                promise.succeed(item)
                            } else {
                                promise.fail(ZenError.recordNotSave)
                            }
                        case .failure(let err):
                            promise.fail(err)
                        }
                    }
                } else {
                    item.basketUpdated = Int.now()
                    item.saveAsync().whenComplete { result in
                        switch result {
                        case .success(let id):
                            item.basketId = id as! Int
                            promise.succeed(item)
                        case .failure(let err):
                            promise.fail(err)
                        }
                    }
                }
            }
            query.whenFailure { err in
                promise.fail(err)
            }
        }
        connect.whenFailure { err in
            promise.fail(err)
        }

        return promise.futureResult
    }
    
    func updateBasket(id: Int, item: Basket) -> EventLoopFuture<Bool> {
        let promise: EventLoopPromise<Bool> = ZenPostgres.pool.newPromise()

        let connect = ZenPostgres.pool.connectAsync()
        connect.whenSuccess { conn in
            defer { conn.disconnect() }

            let current = Basket(connection: conn)
            let query = current.getAsync(id)
            query.whenSuccess {
                if current.basketId == 0 {
                    promise.fail(ZenError.recordNotFound)
                    return
                }
                current.basketQuantity = item.basketQuantity
                current.basketUpdated = Int.now()
                current.updateAsync(
                    cols: ["basketQuantity", "basketUpdated"],
                    params: [current.basketQuantity, current.basketUpdated],
                    id: "basketId",
                    value: current.basketId
                ).whenComplete { result in
                    switch result {
                    case .success(let count):
                        promise.succeed(count > 0)
                    case .failure(let err):
                        promise.fail(err)
                    }
                }
            }
            query.whenFailure { err in
                promise.fail(err)
            }
        }
        connect.whenFailure { err in
            promise.fail(err)
        }
        
        return promise.futureResult
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
        let promise: EventLoopPromise<Cost> = ZenPostgres.pool.newPromise()

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
        
        File()
            .getDataAsync(filename: "shippingcost.csv", size: .csv)
            .whenComplete { result in
                switch result {
                case .success(let bytes):
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
                                promise.succeed(cost)
                                return
                            }
                        }
                    }
                    //promise.fail(ZenError.recordNotFound)
                case .failure(let err):
                    promise.fail(err)
                }
            }

        return promise.futureResult
    }

    func addOrder(registryId: Int, order: OrderModel) -> EventLoopFuture<Movement> {
        let promise: EventLoopPromise<Movement> = ZenPostgres.pool.newPromise()
        
        let repository = ZenIoC.shared.resolve() as MovementProtocol
        
        let connect = ZenPostgres.pool.connectAsync()
        connect.whenSuccess { connection in
            defer { connection.disconnect() }

            do {
                let items: [Basket] = try Basket(connection: connection).query(whereclause: "registryId = $1", params: [registryId])
                if items.count == 0 {
                    throw ZenError.recordNotFound
                }

                let registry = Registry(connection: connection)
                try registry.get(registryId)
                if registry.registryId == 0 {
                    throw ZenError.recordNotFound
                }
                
                var store = Store(connection: connection)
                let stores: [Store] = try store.query(orderby: ["storeId"], cursor: Cursor(limit: 1, offset: 0))
                if stores.count == 1 {
                    store = stores.first!
                }
                let causals: [Causal] = try Causal(connection: connection).query(
                    whereclause: "causalBooked = $1 AND causalQuantity = $2 AND causalIsPos = $3",
                    params: [1, -1 , true],
                    orderby: ["causalId"],
                    cursor: Cursor(limit: 1, offset: 0)
                )
                if causals.count == 0 {
                    throw ZenError.error("no causal found")
                }
                
                let movement = Movement(connection: connection)
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
                    let movementArticle = MovementArticle(connection: connection)
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
                
                promise.succeed(movement)
            } catch {
                promise.fail(error)
            }
        }
        connect.whenFailure { err in
            promise.fail(err)
        }

        return promise.futureResult;
    }

    func getOrders(registryId: Int) -> EventLoopFuture<[Movement]> {
        return Movement().queryAsync(whereclause: "movementRegistry ->> $1 = $2",
                                params: ["registryId", registryId],
                                orderby: ["movementId DESC"])
    }

    func getOrder(registryId: Int, id: Int) -> EventLoopFuture<Movement> {
        let promise: EventLoopPromise<Movement> = ZenPostgres.pool.newPromise()

        let query: EventLoopFuture<[Movement]> = Movement()
            .queryAsync(
                whereclause: "movementRegistry ->> $1 = $2 AND movementId = $3",
                params: ["registryId", registryId, id],
                cursor: Cursor(limit: 1, offset: 0)
            )
        query.whenSuccess { items in
            if let item = items.first {
                promise.succeed(item)
            }
        }
        query.whenFailure { err in
            promise.fail(err)
        }
        
        return promise.futureResult
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

