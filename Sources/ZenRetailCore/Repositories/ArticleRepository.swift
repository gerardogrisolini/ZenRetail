//
//  ArticleRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//n
//

import Foundation
import NIO
import PostgresNIO
import ZenPostgres

struct ArticleRepository : ArticleProtocol {

    private func newNumber(productId: Int, connection: PostgresConnection) -> EventLoopFuture<Int> {
        let article = Article(connection: connection)
        let sql = "SELECT COALESCE(MAX(\"articleNumber\"),0) AS counter FROM \"\(article.table)\" WHERE \"productId\" = \(productId)";
        return article.sqlRowsAsync(sql).map { rows -> Int in
            return (rows.first?.column("counter")?.int ?? 0) + 1
        }
    }

    func build(productId: Int) -> EventLoopFuture<Result> {
        return ZenPostgres.pool.connect().flatMap { connection -> EventLoopFuture<Result> in
            defer { connection.disconnect() }

            let product = Product(connection: connection)
            product.productId = productId
            return product.makeAttributesAsync().flatMap { () -> EventLoopFuture<Result> in
//                // Add defaults attribute and value if empty
//                if productAttributes.count == 0 {
//                    let defaultAttribute = Attribute(connection: connection)
//                    try defaultAttribute.get(1)
//                    let defaultAttributeValue = AttributeValue(connection: connection)
//                    try defaultAttributeValue.get(1)
//
//                    let productAttribute = ProductAttribute(connection: connection)
//                    productAttribute.productId = productId
//                    productAttribute.attributeId = defaultAttribute.attributeId
//                    productAttribute._attribute = defaultAttribute
//                    try productAttribute.save {
//                        id in productAttribute.productAttributeId = id as! Int
//                    }
//                    let productAttributeValue = ProductAttributeValue(connection: connection)
//                    productAttributeValue.productAttributeId = productAttribute.productAttributeId
//                    productAttributeValue.attributeValueId = defaultAttributeValue.attributeValueId
//                    productAttributeValue._attributeValue = defaultAttributeValue
//                    try productAttribute.save {
//                        id in productAttribute.productAttributeId = id as! Int
//                    }
//                    productAttribute._attributeValues.append(productAttributeValue)
//                    productAttributes.append(productAttribute)
//                }
                
                // Create matrix indexes
                var indexes = [[Int]]()
                for attribute in product._attributes {
                    let count = attribute._attributeValues.count - 1
                    if count == -1 {
                        let err = ZenError.error("Not values found for attribute: \(attribute._attribute.attributeName)")
                        return connection.eventLoop.makeFailedFuture(err)
                    }
                    indexes.append([0, count])
                }
                let lastIndex = indexes.count - 1
                
                // Number of variation
                return self.newNumber(productId: productId, connection: connection).flatMap { newNumber -> EventLoopFuture<Result> in
                    var number = newNumber
                    
                    // Invalidate product and articles
                    product.update(
                        cols: ["productIsValid", "productUpdated"],
                        params: [false, Int.now()],
                        id: "productId",
                        value: productId
                    ).whenComplete { _ in }

                    Article(connection: connection).update(
                        cols: ["articleIsValid"],
                        params: [false],
                        id: "productId",
                        value: productId
                    ).whenComplete { _ in }

                    // Creation articles
                    let company = Company()
                    return company.select(connection: connection).flatMap { () -> EventLoopFuture<Result> in
                        let promise = connection.eventLoop.makePromise(of: Result.self)
                        let promiseCheck = connection.eventLoop.makePromise(of: Void.self)
                        
                        var result = Result()
                        var index = 0
                        func subFunc() {
                            
                            // Check if exist article
                            let newArticle = Article(connection: connection)
                            newArticle.productId = productId
                            var sql =
                                "SELECT a.* " +
                                "FROM \"Article\" as a " +
                                "LEFT JOIN \"ArticleAttributeValue\" as b ON a.\"articleId\" = b.\"articleId\" " +
                                "WHERE a.\"productId\" = \(productId) AND b.\"attributeValueId\" IN ("
                            for i in 0...lastIndex {
                                if i > 0 {
                                    sql += ","
                                }
                                sql += product._attributes[i]._attributeValues[indexes[i][0]].attributeValueId.description
                            }
                            sql += ") GROUP BY a.\"articleId\" HAVING count(b.\"attributeValueId\") = \(lastIndex + 1)"
                            
                            newArticle.sqlRowsAsync(sql).whenSuccess { rows in
                                if rows.count > 0 {
                                    newArticle.decode(row: rows[0])
                                    newArticle.update(
                                        cols: ["articleIsValid"],
                                        params: [true],
                                        id: "articleId",
                                        value: newArticle.articleId
                                    ).whenComplete { _ in
                                        result.updated += 1
                                    }
                                } else {
                                    // Add article
                                    let counter = Int(company.barcodeCounterPrivate)! + 1
                                    company.barcodeCounterPrivate = counter.description
                                    let barcode = Barcode()
                                    barcode.barcode = String(company.barcodeCounterPrivate).checkdigit()
                                    
                                    newArticle.articleNumber = number
                                    newArticle.articleBarcodes = [barcode]
                                    newArticle.articleIsValid = true;
                                    
                                    self.add(item: newArticle).whenSuccess { id in
                                        // Add article attribute values
                                        for i in 0...lastIndex {
                                            let articleAttributeValue = ArticleAttributeValue(connection: connection)
                                            articleAttributeValue.articleId = id
                                            articleAttributeValue.attributeValueId = product._attributes[i]._attributeValues[indexes[i][0]].attributeValueId
                                            self.addAttributeValue(item: articleAttributeValue).whenComplete { _ in }
                                        }
                                        result.added += 1
                                        number += 1
                                    }
                                }
                                
                                // Recalculate matrix indexes
                                index = lastIndex
                                while index >= 0 {
                                    if indexes[index][0] < indexes[index][1] {
                                        indexes[index][0] += 1
                                        break
                                    }
                                    index -= 1
                                    if index > -1 && indexes[index][0] < indexes[index][1] {
                                        for i in index + 1...lastIndex {
                                            indexes[i][0] = 0
                                        }
                                    }
                                }
                                
                                if index < 0 {
                                    promiseCheck.succeed(())
                                } else {
                                    subFunc()
                                }
                            }
                        }
                        subFunc()

                        promiseCheck.futureResult.whenComplete { _ in
                            // Clean articles
                            self.get(connection: connection, productId: productId, storeIds: "0").whenSuccess { articles in
                                result.articles = articles
                                
                                let subPromise = connection.eventLoop.makePromise(of: Void.self)
                                
                                for (i, item) in result.articles.enumerated() {
                                    if !item.articleIsValid {
                                        if item._attributeValues.count == 0 {
                                            item.articleIsValid = true
                                            item.update(cols: ["articleIsValid"], params: [true], id:"articleId", value: item.articleId).whenComplete { _ in }
                                            continue
                                        }
                                        ArticleAttributeValue(connection: connection).delete(key: "articleId", value: item.articleId).whenComplete { _ in
                                            item.connection = connection
                                            item.delete().whenComplete { _ in }
                                        }
                                        result.articles.remove(at: i - result.deleted)
                                        result.deleted += 1
                                    }
                                    if i == result.articles.count - 1 {
                                        subPromise.succeed(())
                                    }
                                }
                                
                                subPromise.futureResult.whenSuccess { _ in
                                    // Check integrity
                                    var count: Int = 1
                                    for attribute in product._attributes {
                                        count *= attribute._attributeValues.count
                                    }
                                    if result.articles.count != count {
                                        let err = ZenError.error("Integrity error: \(count) budgeted items and \(result.articles.count) items found")
                                        promise.fail(err)
                                        return
                                    }

                                    // Commit update product and barcode counter
                                    company.update(connection: connection, key: "barcodeCounterPrivate", value: company.barcodeCounterPrivate).whenComplete { _ in }
                                    product.update(cols: ["productIsValid", "productUpdated"], params: [true, Int.now()], id:"productId", value: product.productId).whenComplete { _ in
                                        promise.succeed(result)
                                    }
                                }
                            }
                        }
                        
                        return promise.futureResult
                    }
                }
            }
        }
    }
    
    func get(productId: Int, storeIds: String) -> EventLoopFuture<[Article]> {
        return ZenPostgres.pool.connect().flatMap { connection -> EventLoopFuture<[Article]> in
            defer { connection.disconnect() }
            return self.get(connection: connection, productId: productId, storeIds: storeIds)
        }
    }

    func get(connection: PostgresConnection, productId: Int, storeIds: String) -> EventLoopFuture<[Article]> {
        let product = Product(connection: connection)
        product.productId = productId
        return product.makeArticlesAsync(storeIds).map { () -> [Article] in
            return product._articles
        }
    }

    func get(id: Int) -> EventLoopFuture<Article> {
        let article = Article()
        return article.get(id).map { () -> Article in
            article
        }
    }
    
    func getStock(productId: Int, storeIds: String, tagId: Int) -> EventLoopFuture<ArticleForm> {
        return ZenPostgres.pool.connect().flatMap { connection -> EventLoopFuture<ArticleForm> in
            defer { connection.disconnect() }

            var header = [String]()
            var body = [[ArticleItem]]()
            
            var productAttributeValues = [ProductAttributeValue]()
            let product = Product(connection: connection)
            product.productId = productId
            return product.makeAttributesAsync().flatMap { () -> EventLoopFuture<ArticleForm> in
            
                let lenght = product._attributes.count - 1;
                if (lenght > 0) {
                    for attribute in product._attributes {
                        header.append(attribute._attribute.attributeName)
                        productAttributeValues.append(contentsOf: attribute._attributeValues)
                    }
                    header.removeLast()
                    
                    for value in product._attributes[lenght]._attributeValues {
                        header.append(value._attributeValue.attributeValueName)
                    }
                }
                
                return self.get(connection: connection, productId: productId, storeIds: storeIds).map { articles -> ArticleForm in
                    
                    let grouped = Dictionary(grouping: articles) {
                        $0._attributeValues.dropLast().reduce("") { a,b in
                            "\(a)#\(b.attributeValueId)"
                        }
                    }
                    
                    for group in grouped.sorted(by: { $0.key < $1.key }) {
                        var row = [ArticleItem]()
                        var isFirst = true;
                        for article in group.value {
                            
                            var barcode: Barcode?
                            if tagId > 0 {
                                barcode = article.articleBarcodes.first(where: { $0.tags.contains(where: { $0.valueId == tagId }) })
                            } else {
                                barcode = article.articleBarcodes.first(where: { $0.tags.count == 0 })
                            }
                            
                            let articleItem = ArticleItem(
                                id: article.articleId,
                                value: barcode?.barcode ?? "",
                                stock: article._quantity,
                                booked: article._booked,
                                data: 0.0
                            )
                            if (isFirst) {
                                for value in article._attributeValues {
                                    let productAttributeValue = productAttributeValues.first(where: { pair -> Bool in
                                        return pair._attributeValue.attributeValueId == value.attributeValueId
                                    })
                                    let articleLabel = ArticleItem(
                                        id: 0,
                                        value: productAttributeValue?._attributeValue.attributeValueName ?? "",
                                        stock: 0.0,
                                        booked: 0.0,
                                        data: 0.0
                                    )
                                    row.append(articleLabel);
                                }
                                isFirst = false;
                                if row.count > 0 {
                                    row[row.count - 1] = articleItem;
                                }
                            } else {
                                row.append(articleItem);
                            }
                        }
                        body.append(row)
                    }
                    
                    return ArticleForm(header: header, body: body)
                }
            }
        }
	}
	
    func getGrouped(productId: Int) -> EventLoopFuture<[GroupItem]> {
        return ZenPostgres.pool.connect().flatMap { connection -> EventLoopFuture<[GroupItem]> in
            defer { connection.disconnect() }

            let query: EventLoopFuture<[Article]> = Article(connection: connection)
                .query(whereclause: "productId = $1", orderby: ["articleId"])

            return query.flatMap { articles -> EventLoopFuture<[GroupItem]> in
                let promise = connection.eventLoop.makePromise(of:  [GroupItem].self)
                var rows = [GroupItem]()
                for (i, row) in articles.enumerated() {
                    let data = row.articleBarcodes.first(where: { $0.tags.count == 0 })
                    if let barcode = data?.barcode {
                        let product = Product(connection: connection)
                        product.get(barcode: barcode).whenComplete { _ in
                            if product.productId != productId {
                                rows.append(GroupItem(id: row.articleId, barcode: barcode, product: product))
                            }
                            if i == articles.count - 1 {
                                promise.succeed(rows)
                            }
                        }
                    } else if i == articles.count - 1 {
                        promise.succeed(rows)
                    }
                }
                
                return promise.futureResult
            }
        }
    }

    func add(item: Article) -> EventLoopFuture<Int> {
        item.articleCreated = Int.now()
        item.articleUpdated = Int.now()
        return item.save().map { id -> Int in
            item.articleId = id as! Int
            return item.articleId
        }
    }
    
    func addGroup(item: Article) -> EventLoopFuture<GroupItem> {
        return ZenPostgres.pool.connect().flatMap { connection -> EventLoopFuture<GroupItem> in
            defer { connection.disconnect() }
            item.connection = connection
            
            let barcode = item.articleBarcodes.first!.barcode
            let product = Product(connection: connection)
            return product.get(barcode: barcode).flatMap { () -> EventLoopFuture<GroupItem> in
                item.productId = product.productId
                item.articleCreated = Int.now()
                item.articleUpdated = Int.now()
                return item.save().map { id -> GroupItem in
                    item.articleId = id as! Int
                    return GroupItem(id: item.articleId, barcode: barcode, product: product)
                }
            }
        }
    }

    func update(id: Int, item: Article) -> EventLoopFuture<Bool> {
        return ZenPostgres.pool.connect().flatMap { connection -> EventLoopFuture<Bool> in
            defer { connection.disconnect() }

            let item = Article(connection: connection)
            return item.get(id).flatMap { () -> EventLoopFuture<Bool> in
                // TODO: check this in test
                if let newBarcode = item.articleBarcodes.first {
                    var barcode: Barcode?
                    
                    if newBarcode.tags.count > 0 {
                        barcode = item.articleBarcodes.first(where: { $0.tags.contains(where: { $0.valueId == newBarcode.tags.first?.valueId }) })
                    } else {
                        barcode = item.articleBarcodes.first(where: { $0.tags.count == 0 })
                    }
                    
                    if let barcode = barcode {
                        barcode.barcode = newBarcode.barcode
                        item.articleUpdated = Int.now()
                        return item.save().map { id -> Bool in
                            return true
                        }
                    }
                }
                return connection.eventLoop.future(false)
            }
        }
    }
    
    func delete(id: Int) -> EventLoopFuture<Bool> {
        return Article().delete(id).map { bool -> Bool in
            bool
        }
    }

    func addAttributeValue(item: ArticleAttributeValue) -> EventLoopFuture<Int> {
        return item.save().map { id -> Int in
            item.articleAttributeValueId = id as! Int
            return item.articleAttributeValueId
        }
    }
    
    func removeAttributeValue(id: Int) -> EventLoopFuture<Bool> {
        return ArticleAttributeValue().delete(id).map { bool -> Bool in
            bool
        }
    }
}
