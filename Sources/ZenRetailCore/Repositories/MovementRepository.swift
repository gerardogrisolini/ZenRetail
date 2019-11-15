//
//  MovementRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

import NIO
import PostgresNIO
import ZenPostgres


enum ActionType {
    case Booking
    case Unbooking
    case Delivering
    case Stoking
}

struct MovementRepository : MovementProtocol {

    func getPayments() -> [Item] {
        var items = [Item]()
        items.append(Item(id: "None", value: "None"))
        items.append(Item(id: "Cash", value: "Cash"))
        items.append(Item(id: "PayPal", value: "PayPal - Credit card"))
        items.append(Item(id: "BankTransfer", value: "Bank transfer"))
        items.append(Item(id: "CashOnDelivery", value: "Cash on delivery"))
        return items
    }

    func getShippings() -> [Item] {
        var status = [Item]()
        status.append(Item(id: "None", value: "None"))
        status.append(Item(id: "Standard", value: "Standard"))
        status.append(Item(id: "Express", value: "Express"))
        return status
    }

    func getStatus() -> [ItemValue] {
        var status = [ItemValue]()
        status.append(ItemValue(value: "New"))
        status.append(ItemValue(value: "Processing"))
        status.append(ItemValue(value: "Canceled"))
        status.append(ItemValue(value: "Completed"))
        return status
    }
    
    func getAll() -> EventLoopFuture<[Movement]> {
        return Movement().query(cursor: Cursor(limit: 1000, offset: 0))
    }
    
    func getAll(device: String, user: String, date: Int) -> EventLoopFuture<[Movement]> {

        let movement = Movement()
        let sql = movement.querySQL(
            orderby: ["Movement.movementId", "MovementArticle.movementArticleId"],
            joins: [
                DataSourceJoin(
                    table: "MovementArticle",
                    onCondition: "ProductAttribute.movementId = MovementArticle.movementId",
                    direction: .LEFT
                )
            ]
        )
        
        return movement.sqlRowsAsync(sql).map { rows -> [Movement] in
            var movements = [Movement]()
            
            let groups = Dictionary(grouping: rows) { row in
                row.column("movementId")!.int!
            }
            
            for group in groups.sorted(by: { $0.key < $1.key }) {
                let mov = Movement()
                mov.decode(row: group.value.first!)
                for att in group.value {
                    let a = MovementArticle()
                    a.decode(row: att)
                    mov._items.append(a)
                }
                movements.append(mov)
            }
            
            return movements
        }
    }

    func getWarehouse(date: Int, store: Int) -> EventLoopFuture<[Whouse]> {
        let store = store > 0 ? "AND a.\"movementStore\" ->> 'storeId' = '\(store)'" : ""
        let sql = """
SELECT CAST (b."movementArticleProduct" ->> 'productId' AS INTEGER) AS id,
b."movementArticleProduct" ->> 'productCode' AS sku,
b."movementArticleProduct" ->> 'productName' AS name,
a."movementCausal" ->> 'causalQuantity' as oper,
SUM(b."movementArticleQuantity") AS value
FROM "Movement" AS a
LEFT JOIN "MovementArticle" AS b ON a."movementId" = b."movementId"
WHERE a."movementStatus" = 'Completed' AND a."movementDate" <= \(date)
AND a."movementCausal" ->> 'causalQuantity' <> '0' \(store)
GROUP BY id, sku, name, oper
ORDER BY name, oper
"""
        let article = Article()
        return article.sqlRowsAsync(sql).map { items -> [Whouse] in
            var whouses = [Whouse]()
            var whouse = Whouse()
            for i in 0...items.count - 1 {
                let item = items[i]
                
                whouse.id = item.column("id")?.int ?? 0
                whouse.sku = item.column("sku")?.string ?? ""
                whouse.name = item.column("name")?.string ?? ""
                let oper = item.column("oper")?.string ?? ""
                if oper == "1" {
                    whouse.loaded = item.column("value")?.double ?? 0
                } else {
                    whouse.unloaded = item.column("value")?.double ?? 0
                }

                let nextIndex = i + 1
                if nextIndex == items.count || items[nextIndex].column("id")?.int != whouse.id {
                    whouse.stock = whouse.loaded - whouse.unloaded
                    whouses.append(whouse)
                    whouse = Whouse()
                }
            }
            
            return whouses
        }
    }

    func getSales(period: Period) -> EventLoopFuture<[MovementArticle]> {
        let items = MovementArticle()
        let sql = """
SELECT "MovementArticle".*, "Movement".*
FROM "MovementArticle"
INNER JOIN "Movement" ON "MovementArticle"."movementId" = "Movement"."movementId"
WHERE "Movement"."movementDate" >= \(period.start)
AND "Movement"."movementDate" <= \(period.finish)
AND ("Movement"."idInvoice" > '0' OR "Movement"."movementCausal" ->> 'causalIsPos' = 'true')
AND "Movement"."movementStatus" = 'Completed'
ORDER BY "MovementArticle"."movementArticleId"
"""
        return items.query(sql: sql)
    }
    
    func getReceipted(period: Period) -> EventLoopFuture<[Movement]> {
        return Movement().query(
            whereclause: "movementDate >= $1 AND movementDate <= $2 AND movementCausal ->> $3 = $4 AND movementStatus = $5",
            params: [period.start, period.finish, "causalIsPos", true, "Completed"],
            orderby: ["movementDevice", "movementDate", "movementNumber"])
    }
    
    func get(id: Int, connection: PostgresConnection) -> EventLoopFuture<Movement> {
        let item = Movement(connection: connection)
        return item.get(id).map { () -> Movement in
            item
        }
    }
    
    func get(registryId: Int) -> EventLoopFuture<[Movement]> {
        return Movement().query(whereclause: "movementRegistry ->> $1 = $2 AND idInvoice = $3 AND movementStatus = $4",
                        params: ["registryId", registryId, 0, "Completed"],
                        orderby: ["movementId"])
    }
    
    func add(item: Movement) -> EventLoopFuture<Int> {

        func addItem() -> EventLoopFuture<Int> {
            item.movementUpdated = Int.now()
            
            func saveItem() -> EventLoopFuture<Int> {
                return item.save().map { id -> Int in
                    item.movementId = id as! Int
                    return item.movementId
                }
            }
            
            if !item.movementRegistry.registryName.isEmpty {
                let registry = item.movementRegistry
                if registry.registryId <= 0 {
                    registry.registryId = 0
                    registry.registryCreated = registry.registryUpdated
                    return registry.save().flatMap { id -> EventLoopFuture<Int> in
                        registry.registryId = id as! Int
                        item.movementRegistry = registry
                        return saveItem()
                    }
                } else if registry.registryUpdated > 0 {
                    let current = Registry()
                    return current.get(registry.registryId).flatMap { () -> EventLoopFuture<Int> in
                        if current.registryUpdated < registry.registryUpdated {
                            registry.save().whenComplete { _ in }
                        }
                        return saveItem()
                    }
                }
            }
            
            return saveItem()
        }
        
        if item.movementNumber == 0 {
            return item.newNumber().flatMap { () -> EventLoopFuture<Int> in
                return addItem()
            }
        }
        
        return addItem()
    }
    
    func update(id: Int, item: Movement) -> EventLoopFuture<Bool> {
        let conn = item.connection!

        return self.get(id: id, connection: conn).flatMap { current -> EventLoopFuture<Bool> in
            current.connection = conn
            
            func save() -> EventLoopFuture<Bool> {
                current.movementStatus = item.movementStatus
                current.movementNote = item.movementNote
                current.movementUpdated = item.movementUpdated
                return current.save().map { id -> Bool in
                    id as! Int > 0
                }
            }

            item.movementUpdated = Int.now()
            if item.movementStatus == "New" {
                current.movementNumber = item.movementNumber
                current.movementDate = item.movementDate
                current.movementDesc = item.movementDesc
                current.movementUser = item.movementUser
                current.movementDevice = item.movementDevice
                current.movementCausal = item.movementCausal
                current.movementStore = item.movementStore
                current.movementRegistry = item.movementRegistry
                current.movementTags = item.movementTags
                current.movementPayment = item.movementPayment
                current.movementShipping = item.movementShipping
                current.movementShippingCost = item.movementShippingCost
                return current.getAmount().flatMap { () -> EventLoopFuture<Bool> in
                    return save()
                }
                
            } else if current.movementStatus == "New" && item.movementStatus == "Processing" {
                return self.process(movement: current, actionTypes: [.Delivering, .Booking]).flatMap { () -> EventLoopFuture<Bool> in
                    return current.getAmount().flatMap { () -> EventLoopFuture<Bool> in
                        return save()
                    }
                }
            }
            else if current.movementStatus == "Processing" && item.movementStatus == "Canceled" {
                return self.process(movement: current, actionTypes: [.Unbooking]).flatMap { () -> EventLoopFuture<Bool> in
                    return save()
                }
            }
            else if current.movementStatus != "Completed" && item.movementStatus == "Completed" {
                var actions: [ActionType] = [.Stoking]
                if current.movementStatus == "New" {
                    actions = [.Delivering, .Stoking]
                }
                else if current.movementStatus == "Processing" {
                    actions = [.Unbooking, .Stoking]
                }
                
                return self.process(movement: current, actionTypes: actions).flatMap { () -> EventLoopFuture<Bool> in
                    return current.getAmount().flatMap { () -> EventLoopFuture<Bool> in
                        return save()
                    }
                }
            }
            
            return conn.eventLoop.future(true)
        }
    }
    
    func delete(id: Int) -> EventLoopFuture<Bool> {
        return ZenPostgres.pool.connect().flatMap { connection -> EventLoopFuture<Bool> in
            defer { connection.disconnect() }
            return MovementArticle(connection: connection).delete(key: "movementId", value: id).flatMap { id -> EventLoopFuture<Bool> in
                return Movement(connection: connection).delete(id)
            }
        }
    }
    
    fileprivate func makeBarcodesForTags(_ movement: Movement, _ item: MovementArticle, _ article: Article, _ company: Company) -> EventLoopFuture<Void> {
        let connection = movement.connection!

        if movement.movementTags.count == 0 { return connection.eventLoop.future() }
            
        let price = Price()
        if movement.movementCausal.causalQuantity < 0 {
            price.selling = item.movementArticlePrice
            if price.purchase == 0 {
                price.purchase = item.movementArticleProduct.productPrice.purchase
            }
        } else {
            price.purchase = item.movementArticlePrice
            if price.selling == 0 {
                price.selling = item.movementArticleProduct.productPrice.selling
            }
        }
        
        func saveBarcode(_ barcode: String) -> EventLoopFuture<Void> {
            return item.update(cols: ["movementArticleBarcode"], params: [barcode], id: "movementArticleId", value: item.movementArticleId).flatMap { count -> EventLoopFuture<Void> in
                if count == 0 {
                    return connection.eventLoop.future(error: ZenError.recordNotSave)
                }
                article.articleIsValid = true;
                article.productId = item.movementArticleProduct.productId
                article.articleUpdated = Int.now()
                return article.save().map { id -> Void in
                    article.articleId = id as! Int
                }
            }
        }
        
        if let barcode = article.articleBarcodes.first(where: { $0.tags.containsSameElements(as: movement.movementTags) }) {
            barcode.price = price
            barcode.discount = item.movementArticleProduct.productDiscount
            return saveBarcode(barcode.barcode)
        } else {
            let barcode = Barcode()
            barcode.tags = movement.movementTags
            barcode.price = price
            barcode.discount = item.movementArticleProduct.productDiscount
            
            if barcode.tags.first(where: { $0.valueName == "Amazon" }) != nil {
                let counter = Int(company.barcodeCounterPublic)! + 1
                company.barcodeCounterPublic = counter.description
                barcode.barcode = String(company.barcodeCounterPublic).checkdigit()
                Product(connection: connection).update(cols: ["productAmazonUpdated"], params: [1], id: "productId", value: article.productId).whenComplete { _ in }
            } else {
                let counter = Int(company.barcodeCounterPrivate)! + 1
                company.barcodeCounterPrivate = counter.description
                barcode.barcode = String(company.barcodeCounterPrivate).checkdigit()
            }
            article.articleBarcodes.append(barcode)

            return saveBarcode(barcode.barcode)
        }
   }
    
    func process(movement: Movement, actionTypes: [ActionType]) -> EventLoopFuture<Void> {
        let connection = movement.connection!
        let promise = connection.eventLoop.makePromise(of: Void.self)
        
        let storeId = movement.movementStore.storeId
        let quantity = movement.movementCausal.causalQuantity
        let booked = movement.movementCausal.causalBooked
        
        let company = Company()
        company.select(connection: connection).whenComplete { result in
            switch result {
            case .success(_):
                let query: EventLoopFuture<[MovementArticle]> = MovementArticle(connection: connection).query(whereclause: "movementId = $1", params: [movement.movementId])
                query.whenSuccess { articles in
                    let count = articles.count - 1
                    for actionType in actionTypes {
                        for (i, item) in articles.enumerated() {
                        
                            if actionType == .Delivering {
                                item.connection = connection
                                item.movementArticleDelivered = item.movementArticleQuantity
                                item.update(
                                    cols: ["movementArticleDelivered"],
                                    params: [item.movementArticleQuantity],
                                    id: "movementArticleId",
                                    value: item.movementArticleId
                                ).whenComplete { _ in
                                    if i == count && actionType == actionTypes.last! {
                                        promise.succeed(())
                                    }
                                }
                                continue
                            }
                            
                            let article = item.movementArticleProduct._articles.first!
                            let articleId = article.articleId
                            var stock = Stock(connection: connection)
                            let stocksQuery: EventLoopFuture<[Stock]> = stock.query(
                                whereclause: "articleId = $1 AND storeId = $2",
                                params: [ articleId, storeId ],
                                cursor: Cursor(limit: 1, offset: 0))
                            stocksQuery.whenSuccess { stocks in
                                
                                func finalProcess() {

                                    func finalSubProcess() {
                                        stock.save().whenComplete { _ in
                                            if i == count && actionType == actionTypes.last! {
                                                promise.succeed(())
                                            }
                                        }
                                    }

                                    switch actionType {
                                    case .Booking:
                                        if booked > 0 {
                                            stock.stockBooked += item.movementArticleQuantity
                                        } else {
                                            stock.stockBooked -= item.movementArticleQuantity
                                        }
                                        finalSubProcess()
                                    case .Unbooking:
                                        stock.stockBooked -= item.movementArticleQuantity
                                        finalSubProcess()
                                    default:
                                        if quantity > 0 {
                                            stock.stockQuantity += item.movementArticleDelivered
                                        } else if quantity < 0 {
                                            stock.stockQuantity -= item.movementArticleDelivered
                                        }
                                        
                                        self.makeBarcodesForTags(movement, item, article, company).whenComplete { res in
                                            switch res {
                                            case .success(_):
                                                finalSubProcess()
                                            case .failure(let err):
                                                if i == count && actionType == actionTypes.last! {
                                                    promise.fail(err)
                                                }
                                            }
                                        }
                                    }
                                }

                                if (stocks.count == 1) {
                                    stock = stocks.first!
                                    finalProcess()
                                } else {
                                    stock.storeId = storeId
                                    stock.articleId = articleId
                                    stock.save().whenComplete { res in
                                        switch res {
                                        case .success(let id):
                                            stock.stockId = id as! Int
                                            finalProcess()
                                        case .failure(let err):
                                            promise.fail(err)
                                        }
                                    }
                                }
                            }
                            stocksQuery.whenFailure { err in
                                promise.fail(err)
                            }
                        }
                    }
                }
                query.whenFailure { err in
                    promise.fail(err)
                }
            case .failure(let err):
                promise.fail(err)
            }
        }
        
        return promise.futureResult.flatMap { () -> EventLoopFuture<Void> in
            return company.save()
        }
    }
    
    func clone(sourceId: Int, connection: PostgresConnection) -> EventLoopFuture<Movement> {
        return self.get(id: sourceId, connection: connection).flatMap { item -> EventLoopFuture<Movement> in
            item.connection = connection
            item.movementId = 0
            item.movementNumber = 0
            item.movementDate = Int.now()
            item.movementStatus = "New"
            return self.add(item: item).map { id -> Movement in
                item.movementId = id
                return item
            }
        }
    }
}
