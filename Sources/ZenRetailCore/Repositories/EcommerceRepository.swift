//
//  EcommerceRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 25/10/17.
//

import Foundation
import ZenNIO
import ZenPostgres

struct EcommerceRepository : EcommerceProtocol {

    func getCategories() throws -> [Category] {
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
        
        return try Category().query(
            columns: ["DISTINCT Category.*"],
            whereclause: "Publication.publicationStartAt <= $1 AND Publication.publicationFinishAt >= $1 AND Category.categoryIsPrimary = $2 AND Publication.productIsActive = $2",
            params: [Int.now(), true],
            orderby: ["Category.categoryName"],
            joins:  [category, product, publication]
        )
    }

    func getBrands() throws -> [Brand] {
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
        
        let items = Brand()
        return try items.query(
            columns: ["DISTINCT Brand.*"],
            whereclause: "Publication.publicationStartAt <= $1 AND Publication.publicationFinishAt >= $1 AND Product.productIsActive = $2",
            params: [Int.now(), true],
            orderby: ["Brand.brandName"],
            joins:  [product, publication]
        )
    }
    
    
    func getProductsFeatured() throws -> [Product] {
        let publication = DataSourceJoin(
            table: "Publication",
            onCondition: "Product.productId = Publication.productId",
            direction: .INNER
        )
        let brand = DataSourceJoin(
            table: "Brand",
            onCondition: "Product.brandId = Brand.brandId",
            direction: .INNER
        )
        
        let obj = Product()
        let sql = obj.querySQL(
            whereclause: "Publication.publicationFeatured = $1 AND Product.productIsActive = $1 AND Publication.publicationStartAt <= $2 AND Publication.publicationFinishAt >= $2",
            params: [true, Int.now()],
            orderby: ["Publication.publicationStartAt DESC"],
            joins: [publication, brand]
        )
        
        return try obj.rows(sql: sql, barcodes: false)
    }
    
    func getProductsNews() throws -> [Product] {
        let publication = DataSourceJoin(
            table: "Publication",
            onCondition: "Product.productId = Publication.productId",
            direction: .INNER
        )
        let brand = DataSourceJoin(
            table: "Brand",
            onCondition: "Product.brandId = Brand.brandId",
            direction: .INNER
        )
        
        let obj = Product()
        let sql = obj.querySQL(
            whereclause: "Publication.publicationNew = $1 AND Product.productIsActive = $1 AND Publication.publicationStartAt <= $2 AND Publication.publicationFinishAt >= $2",
            params: [true, Int.now()],
            orderby: ["Publication.publicationStartAt DESC"],
            joins: [publication, brand]
        )
        
        return try obj.rows(sql: sql, barcodes: false)
    }
    
    func getProductsDiscount() throws -> [Product] {
        let publication = DataSourceJoin(
            table: "Publication",
            onCondition: "Product.productId = Publication.productId",
            direction: .INNER
        )
        let brand = DataSourceJoin(
            table: "Brand",
            onCondition: "Product.brandId = Brand.brandId",
            direction: .INNER
        )
        
        let obj = Product()
        let sql = obj.querySQL(
            whereclause: "Product.productIsActive = $1 AND Product.productDiscount <> NULL AND (Product.productDiscount ->> 'discountStartAt')::int <= $2 AND (Product.productDiscount ->> 'discountFinishAt')::int >= $2 AND Publication.publicationStartAt <= $2 AND Publication.publicationFinishAt >= $2",
            params: [true, Int.now()],
            orderby: ["Publication.publicationStartAt DESC"],
            joins: [publication, brand]
        )
        
        return try obj.rows(sql: sql, barcodes: false)
    }

    func getProducts(brand: String) throws -> [Product] {
        let obj = Product()
        let sql = obj.querySQL(
            whereclause: "Brand.brandSeo ->> 'permalink' = $1 AND Publication.publicationStartAt <= $2 AND Publication.publicationFinishAt >= $2 AND Product.productIsActive = $3",
            params: [brand, Int.now(), true],
            orderby: ["Product.productName"],
            joins:  [
                DataSourceJoin(
                    table: "Publication",
                    onCondition: "Product.productId = Publication.productId",
                    direction: .INNER),
                DataSourceJoin(
                    table: "Brand",
                    onCondition: "Product.brandId = Brand.brandId",
                    direction: .INNER)
            ]
        )
        
        return try obj.rows(sql: sql, barcodes: false)
    }
    
    func getProducts(category: String) throws -> [Product] {
        let publication = DataSourceJoin(
            table: "Publication",
            onCondition: "Product.productId = Publication.productId",
            direction: .INNER
        )
        let brand = DataSourceJoin(
            table: "Brand",
            onCondition: "Product.brandId = Brand.brandId",
            direction: .INNER
        )
        let productCategories = DataSourceJoin(
            table: "ProductCategory",
            onCondition: "Product.productId = ProductCategory.productId",
            direction: .LEFT
        )
        let Category = DataSourceJoin(
            table: "Category",
            onCondition: "ProductCategory.categoryId = Category.categoryId",
            direction: .INNER
        )

        let obj = Product()
        let sql = obj.querySQL(
            whereclause: "Category.categorySeo ->> 'permalink' = $1 AND Publication.publicationStartAt <= $2 AND Publication.publicationFinishAt >= $2 AND Product.productIsActive = $3",
            params: [category, Int.now(), true],
            orderby: ["Product.productName"],
            joins:  [publication, brand, productCategories, Category]
        )
        
        return try obj.rows(sql: sql, barcodes: false)
    }

    func findProducts(text: String) throws -> [Product] {
        let obj = Product()
        let sql = obj.querySQL(
            whereclause: "LOWER(Product.productName) LIKE $1 AND Publication.publicationStartAt <= $2 AND Publication.publicationFinishAt >= $2 AND Product.productIsActive = $3",
            params: ["%\(text.lowercased())%", Int.now(), true],
            joins:  [
                DataSourceJoin(
                    table: "Publication",
                    onCondition: "Product.productId = Publication.productId",
                    direction: .INNER),
                DataSourceJoin(
                    table: "Brand",
                    onCondition: "Product.brandId = Brand.brandId",
                    direction: .INNER)
            ]
        )
        
        return try obj.rows(sql: sql, barcodes: false)
    }

    func getProduct(name: String) throws -> Product {
        let item = Product()
        let sql = item.querySQL(
            whereclause: "Product.productSeo ->> 'permalink' = $1",
            params: [name],
            joins: [
                DataSourceJoin(
                    table: "Brand",
                    onCondition: "Product.brandId = Brand.brandId",
                    direction: .INNER
                )
            ]
        )
        
        let rows = try item.sqlRows(sql)
        if rows.count == 0 {
            throw ZenError.noRecordFound
        }
        
        item.decode(row: rows.first!)
        try item.makeCategories()
        try item.makeAttributes()
        try item.makeArticles()
        
        return item
    }

    func getBaskets() throws -> [Basket] {
        let registry = DataSourceJoin(
            table: "registries",
            onCondition: "baskets.registryId = registries.registryId",
            direction: .LEFT
        )
        
        let items = Basket()
        return try items.query(joins: [registry])
    }

    func getBasket(registryId: Int) throws -> [Basket] {
        let items = Basket()
        return try items.query(whereclause: "registryId = $1", params: [registryId])
    }
    
    func addBasket(item: Basket) throws {
        let items = try getBasket(registryId: item.registryId)
        let basket = items.first(where: { $0.basketBarcode == item.basketBarcode})
        if let current = basket {
            current.basketQuantity += 1
            current.basketUpdated = Int.now()
            try current.save()
            item.basketId = current.basketId
            item.basketQuantity = current.basketQuantity
            return
        }
        
        item.basketUpdated = Int.now()
        try item.save {
            id in item.basketId = id as! Int
        }
    }
    
    func updateBasket(id: Int, item: Basket) throws {
        let current = Basket()
        try current.get(id)
        if current.basketId == 0 {
            throw ZenError.noRecordFound
        }
        current.basketQuantity = item.basketQuantity
        current.basketUpdated = Int.now()
        try current.save()
    }
    
    func deleteBasket(id: Int) throws {
        let item = Basket()
        item.basketId = id
        try item.delete()
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

    func getShippingCost(id: String, registry: Registry) -> Cost {
        var cost = Cost(value: 0)

        var string: String
        
        let data = FileManager.default.contents(atPath: "./webroot/csv/shippingcost_\(id).csv")
        if let content = data {
            string = String(data: content, encoding: .utf8)!
        } else {
            let defaultData = FileManager.default.contents(atPath: "./webroot/csv/shippingcost.csv")
            if let defaultContent = defaultData {
                string = String(data: defaultContent, encoding: .utf8)!
            } else {
                return cost
            }
        }

        let lines = string.split(separator: "\n")
        for line in lines {
            let columns = line.split(separator: ",", omittingEmptySubsequences: false)
            
            if (columns[0] == registry.registryCountry || columns[0] == "*")
            {
                if let value = Double(columns[4]) {
                    cost.value = value
                }
                if (columns[1] == registry.registryCity)
                {
                    if let value = Double(columns[4]) {
                        cost.value = value
                    }
                    return cost;
                }
            }
        }

        return cost
    }

    func addOrder(registryId: Int, order: OrderModel) throws -> Movement {
        let repository = ZenIoC.shared.resolve() as MovementProtocol
        
        let items = try self.getBasket(registryId: registryId)
        if items.count == 0 {
            throw ZenError.noRecordFound
        }

        let registry = Registry()
        try registry.get(registryId)
        if registry.registryId == 0 {
            throw ZenError.noRecordFound
        }
        
        var store = Store()
        let stores: [Store] = try store.query(orderby: ["storeId"], cursor: Cursor.init(limit: 1, offset: 0))
        if stores.count == 1 {
            store = stores.first!
        }
        let causals: [Causal] = try Causal().query(
            whereclause: "causalBooked = $1 AND causalQuantity = $2 AND causalIsPos = $3",
            params: [1, -1 , true],
            orderby: ["causalId"],
            cursor: Cursor.init(limit: 1, offset: 0)
        )
        if causals.count == 0 {
            throw ZenError.error("no causal found")
        }
        
        let movement = Movement()
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
            let movementArticle = MovementArticle()
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
        
        return movement;
    }

    func getOrders(registryId: Int) throws -> [Movement] {
        let items = Movement()
        return try items.query(whereclause: "movementRegistry ->> 'registryId' = $1",
                               params: [registryId],
                               orderby: ["movementId DESC"])
    }

    func getOrder(registryId: Int, id: Int) throws -> Movement {
        let item = Movement()
        let items: [Movement] = try item.query(whereclause: "movementRegistry ->> 'registryId' = $1 AND movementId = $2",
                                               params: [registryId, id],
                                               cursor: Cursor(limit: 1, offset: 0))
        if items.count > 0 {
            return items.first!
        }
        return item
    }
    
    func getOrderItems(registryId: Int, id: Int) throws -> [MovementArticle] {
        let items = MovementArticle()
        let join = DataSourceJoin(
            table: "Movement",
            onCondition: "MovementArticle.movementId = Movement.movementId",
            direction: .RIGHT
        )
        return try items.query(whereclause: "Movement.movementRegistry ->> 'registryId' = $1 AND MovementArticle.movementId = $2",
                        params: [registryId, id],
                        orderby: ["MovementArticle.movementarticleId"],
                        joins: [join]
        )
    }
}

