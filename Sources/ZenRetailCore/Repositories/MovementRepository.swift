//
//  MovementRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

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
    
    func getAll() throws -> [Movement] {
        return try Movement().query(cursor: Cursor(limit: 1000, offset: 0))
    }
    
    func getAll(device: String, user: String, date: Int) throws -> [Movement] {
        let rows: [Movement] = try Movement().query(
            whereclause: "movementDevice = $1 AND movementUser = $2 AND movementUpdated > $3",
            params: [device, user, date]
        )
        for row in rows {
            let item = MovementArticle()
            row._items = try item.query(
                whereclause: "movementId = $1",
                params: [row.movementId],
                orderby: ["movementArticleId"]
            )
        }
        return rows
    }

    func getWarehouse(date: Int, store: Int) throws -> [Whouse] {
        var whouses = [Whouse]()
        
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
        let items = try article.sqlRows(sql)

        var whouse = Whouse()
        if items.count > 0 {
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
        }
        
        return whouses
    }

    func getSales(period: Period) throws -> [MovementArticle] {
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
        return try items.query(sql: sql)
    }
    
    func getReceipted(period: Period) throws -> [Movement] {
        let items = Movement()
        return try items.query(
            whereclause: "movementDate >= $1 AND movementDate <= $2 AND movementCausal ->> $3 = $4 AND movementStatus = $5",
            params: [period.start, period.finish, "causalIsPos", true, "Completed"],
            orderby: ["movementDevice", "movementDate", "movementNumber"])
    }
    
    func get(id: Int) throws -> Movement? {
        let item = Movement()
        try item.get(id)
        
        return item
    }
    
    func get(registryId: Int) throws -> [Movement] {
        let items = Movement()
        return try items.query(whereclause: "movementRegistry ->> $1 = $2 AND idInvoice = $3 AND movementStatus = $4",
                        params: ["registryId", registryId, 0, "Completed"],
                        orderby: ["movementId"])
    }
    
    func add(item: Movement) throws {
        if item.movementNumber == 0 {
            try item.newNumber()
        }
        item.movementUpdated = Int.now()
        
        if !item.movementRegistry.registryName.isEmpty {
            let registry = item.movementRegistry
            if registry.registryId <= 0 {
                registry.registryId = 0
                registry.registryCreated = registry.registryUpdated
                try registry.save {
                    id in registry.registryId = id as! Int
                }
                item.movementRegistry = registry
            } else if registry.registryUpdated > 0 {
                let current = Registry()
                try current.get(registry.registryId)
                if current.registryUpdated < registry.registryUpdated {
                    try registry.save()
                }
            }
        }
        
        try item.save {
            id in item.movementId = id as! Int
        }
    }
    
    func update(id: Int, item: Movement) throws {
        guard let current = try get(id: id) else {
            throw ZenError.recordNotFound
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
            try current.getAmount()
        } else if current.movementStatus == "New" && item.movementStatus == "Processing" {
            try process(movement: current, actionTypes: [.Delivering, .Booking])
            try current.getAmount()
        }
        else if current.movementStatus == "Processing" && item.movementStatus == "Canceled" {
            try process(movement: current, actionTypes: [.Unbooking])
        }
        else if current.movementStatus != "Completed" && item.movementStatus == "Completed" {
            var actions: [ActionType] = [.Stoking]
            if current.movementStatus == "New" {
                actions = [.Delivering, .Stoking]
            }
            else if current.movementStatus == "Processing" {
                actions = [.Unbooking, .Stoking]
            }
            try process(movement: current, actionTypes: actions)
            try current.getAmount()
        }
        current.movementStatus = item.movementStatus
        current.movementNote = item.movementNote
        current.movementUpdated = item.movementUpdated
        try current.save()
    }
    
    func delete(id: Int) throws {
        let item = Movement()
        item.movementId = id
        try item.delete()
        
        _ = try MovementArticle().delete(key: "movementId", value: id)
    }
    
    fileprivate func makeBarcodesForTags(_ movement: Movement, _ item: MovementArticle, _ article: Article, _ company: Company) throws {
        
        if movement.movementTags.count == 0 { return }
            
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
        
        if let barcode = article.articleBarcodes
                                .first(where: { $0.tags.containsSameElements(as: movement.movementTags) }) {
            barcode.price = price
            barcode.discount = item.movementArticleProduct.productDiscount
            item.movementArticleBarcode = barcode.barcode;
        } else {
            let barcode = Barcode()
            barcode.tags = movement.movementTags
            barcode.price = price
            barcode.discount = item.movementArticleProduct.productDiscount
            
            if barcode.tags.first(where: { $0.valueName == "Amazon" }) != nil {
                let counter = Int(company.barcodeCounterPublic)! + 1
                company.barcodeCounterPublic = counter.description
                barcode.barcode = String(company.barcodeCounterPublic).checkdigit()
                _ = try Product().update(cols: ["productAmazonUpdated"], params: [1], id: "productId", value: article.productId)
            } else {
                let counter = Int(company.barcodeCounterPrivate)! + 1
                company.barcodeCounterPrivate = counter.description
                barcode.barcode = String(company.barcodeCounterPrivate).checkdigit()
            }
            article.articleBarcodes.append(barcode)
            item.movementArticleBarcode = barcode.barcode;
        }
        try item.save()

        article.articleIsValid = true;
        article.productId = item.movementArticleProduct.productId
        article.articleUpdated = Int.now()
        try article.save()
   }
    
    func process(movement: Movement, actionTypes: [ActionType]) throws {
        
        let storeId = movement.movementStore.storeId
        let quantity = movement.movementCausal.causalQuantity
        let booked = movement.movementCausal.causalBooked
        let company = Company()
        try company.select()
        
        let articles: [MovementArticle] = try MovementArticle().query(whereclause: "movementId = $1", params: [movement.movementId])
        for actionType in actionTypes {
            for item in articles {
            
                if actionType == .Delivering {
                    item.movementArticleDelivered = item.movementArticleQuantity
                    _ = try item.update(
                        cols: ["movementArticleDelivered"],
                        params: [item.movementArticleQuantity],
                        id: "movementArticleId",
                        value: item.movementArticleId
                    )
                    continue
                }
                
                let article = item.movementArticleProduct._articles.first!
                let articleId = article.articleId
                var stock = Stock()
                let stocks: [Stock] = try stock.query(
                    whereclause: "articleId = $1 AND storeId = $2",
                    params: [ articleId, storeId ],
                    cursor: Cursor(limit: 1, offset: 0))
                
                if (stocks.count == 1) {
                    stock = stocks.first!
                } else {
                    stock.storeId = storeId
                    stock.articleId = articleId
                    try stock.save {
                        id in stock.stockId = id as! Int
                    }
                }
                
                switch actionType {
                case .Booking:
                    if booked > 0 {
                        stock.stockBooked += item.movementArticleQuantity
                    } else {
                        stock.stockBooked -= item.movementArticleQuantity
                    }
                case .Unbooking:
                    stock.stockBooked -= item.movementArticleQuantity
                default:
                    if quantity > 0 {
                        stock.stockQuantity += item.movementArticleDelivered
                    } else if quantity < 0 {
                        stock.stockQuantity -= item.movementArticleDelivered
                    }
                    
                    try makeBarcodesForTags(movement, item, article, company)
                }
                
                try stock.save()
            }
        }
        
        try company.save()
    }
    
    func clone(sourceId: Int) throws -> Movement {
        let item = (try self.get(id: sourceId))!
        item.movementId = 0
        item.movementNumber = 0
        item.movementDate = Int.now()
        item.movementStatus = "New"
        try self.add(item: item)
        return item
    }
}
