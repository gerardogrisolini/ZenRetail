//
//  ArticleRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//n
//

import Foundation
import ZenPostgres
import PostgresNIO

struct ArticleRepository : ArticleProtocol {

    private func newNumber(productId: Int) throws -> Int {
        let article = Article()
        let sql = "SELECT COALESCE(MAX(\"articleNumber\"),0) AS counter FROM \"\(article.table)\" WHERE \"productId\" = \(productId)";
        let getCount = try article.sqlRows(sql)
        return (getCount.first?.column("counter")?.int ?? 0) + 1
    }

    func build(productId: Int) throws -> Result {
        let connection = try ZenPostgres.pool.connect()
        defer { connection.disconnect() }

        var result = Result()
        let product = Product(connection: connection)
        try product.get(productId)

        // Get product attributes
		var productAttributes: [ProductAttribute] = try ProductAttribute(connection: connection).query(
            whereclause: "ProductAttribute.productId = $1",
            params: [productId],
            orderby: ["ProductAttribute.productAttributeId"],
            joins: [
                DataSourceJoin(
                    table: "Attribute",
                    onCondition: "ProductAttribute.attributeId = Attribute.attributeId"
                )
            ]
        )
        
        // Add defaults attribute and value if empty
        if productAttributes.count == 0 {
            let defaultAttribute = Attribute(connection: connection)
            try defaultAttribute.get(1)
            let defaultAttributeValue = AttributeValue(connection: connection)
            try defaultAttributeValue.get(1)
            
            let productAttribute = ProductAttribute(connection: connection)
            productAttribute.productId = productId
            productAttribute.attributeId = defaultAttribute.attributeId
            productAttribute._attribute = defaultAttribute
            try productAttribute.save {
                id in productAttribute.productAttributeId = id as! Int
            }
            let productAttributeValue = ProductAttributeValue(connection: connection)
            productAttributeValue.productAttributeId = productAttribute.productAttributeId
            productAttributeValue.attributeValueId = defaultAttributeValue.attributeValueId
            productAttributeValue._attributeValue = defaultAttributeValue
            try productAttribute.save {
                id in productAttribute.productAttributeId = id as! Int
            }
            productAttribute._attributeValues.append(productAttributeValue)
            productAttributes.append(productAttribute)
        }
        
        // Create matrix indexes
        var indexes = [[Int]]()
        for attribute in productAttributes {
            try attribute.makeAttributeValues()
            let count = attribute._attributeValues.count - 1
            if count == -1 {
                throw ZenError.error("Not values found for attribute: \(attribute._attribute.attributeName)")
            }
            indexes.append([0, count])
        }
        let lastIndex = indexes.count - 1
        
        // Number of variation
        var number = indexes.last![1] > 0 ? try self.newNumber(productId: productId) : 0

        // Invalidate product and articles
        product.productIsValid = false
        product.productUpdated = Int.now()
        try product.save()

        _ = try Article(connection: connection).update(
            cols: ["articleIsValid"],
            params: [false],
            id: "productId",
            value: productId
        )

        // Creation articles
        let company = Company()
        try company.select(connection: connection)
        var index = 0
        while index >= 0 {
            
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
                sql += productAttributes[i]._attributeValues[indexes[i][0]].attributeValueId.description
            }
            sql += ") GROUP BY a.\"articleId\" HAVING count(b.\"attributeValueId\") = \(lastIndex + 1)"
            
            let current = try newArticle.sqlRows(sql)
            if current.count > 0 {
                newArticle.decode(row: current[0])
                newArticle.productId = productId
                newArticle.articleIsValid = true;
                try newArticle.save()
                result.updated += 1
            }
            else {
                // Add article
                let counter = Int(company.barcodeCounterPrivate)! + 1
                company.barcodeCounterPrivate = counter.description
                let barcode = Barcode()
                barcode.barcode = String(company.barcodeCounterPrivate).checkdigit()
                
                newArticle.articleNumber = number
                newArticle.articleBarcodes = [barcode]
                newArticle.articleIsValid = true;
                try add(item: newArticle)
                
                // Add article attribute values
                for i in 0...lastIndex {
                    let articleAttributeValue = ArticleAttributeValue(connection: connection)
                    articleAttributeValue.articleId = newArticle.articleId
                    articleAttributeValue.attributeValueId = productAttributes[i]._attributeValues[indexes[i][0]].attributeValueId
                    try addAttributeValue(item: articleAttributeValue)
                }
                result.added += 1
                number += 1
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
        }

        // Clean articles
        result.articles = try get(connection: connection, productId: productId, storeIds: "0")
        for (i, item) in result.articles.enumerated() {
            if !item.articleIsValid {
                if item._attributeValues.count == 0 {
                    item.articleIsValid = true
                    _ = try item.update(cols: ["articleIsValid"], params: [true], id:"articleId", value: item.articleId)
                    continue
                }
                _ = try ArticleAttributeValue(connection: connection).delete(key: "articleId", value: item.articleId)
                try item.delete()
                result.articles.remove(at: i - result.deleted)
                result.deleted += 1
            }
        }
        
        // Check integrity
        var count: Int = 1
        for attribute in productAttributes {
            count *= attribute._attributeValues.count
        }
        if result.articles.count != count {
            throw ZenError.error("Integrity error: \(count) budgeted items and \(result.articles.count) items found")
        }

        // Commit update product and barcode counter
        product.productIsValid = true
        product.productUpdated = Int.now()
        try product.save()
        try company.update(connection: connection, key: "barcodeCounterPrivate", value: company.barcodeCounterPrivate)
        
        return result
    }
    
    func get(productId: Int, storeIds: String) throws -> [Article] {
        let connection = try ZenPostgres.pool.connect()
        defer { connection.disconnect() }
        return try get(connection: connection, productId: productId, storeIds: storeIds)
    }

    func get(connection: PostgresConnection, productId: Int, storeIds: String) throws -> [Article] {
        let product = Product(connection: connection)
        product.productId = productId
        try product.makeArticles(storeIds)
        return product._articles
    }

    func get(id: Int) -> Article? {
        let item = Article()
        do {
            try item.get(id)
            return item
        } catch {
            return nil
        }
    }
    
    func getStock(productId: Int, storeIds: String, tagId: Int) throws -> ArticleForm {
        let connection = try ZenPostgres.pool.connect()
        defer { connection.disconnect() }

        var header = [String]()
		var body = [[ArticleItem]]()
		
		var productAttributeValues = [ProductAttributeValue]()
        let product = Product(connection: connection)
        product.productId = productId
        try product.makeAttributes()
        
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
		
        let articles = try get(connection: connection, productId: productId, storeIds: storeIds)
		let grouped = articles.groupBy {
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
	
    func getGrouped(productId: Int) throws -> [GroupItem] {
        let connection = try ZenPostgres.pool.connect()
        defer { connection.disconnect() }

        var rows = [GroupItem]()
        let articles: [Article] = try Article(connection: connection)
            .query(whereclause: "productId = $1", orderby: ["articleId"])
        for row in articles {
            let data = row.articleBarcodes.first(where: { $0.tags.count == 0 })
            if let barcode = data?.barcode {
                let product = Product(connection: connection)
                try product.get(barcode: barcode)
                if product.productId != productId {
                    rows.append(GroupItem(id: row.articleId, barcode: barcode, product: product))
                }
            }
        }

        return rows
    }

    func add(item: Article) throws {
        item.articleCreated = Int.now()
        item.articleUpdated = Int.now()
        try item.save {
            id in item.articleId = id as! Int
        }
    }
    
    func addGroup(item: Article) throws -> GroupItem {
        let connection = try ZenPostgres.pool.connect()
        defer { connection.disconnect() }

        item.connection = connection
        
        let barcode = item.articleBarcodes.first!.barcode
        let product = Product(connection: connection)
        try product.get(barcode: barcode)

        item.productId = product.productId
        item.articleCreated = Int.now()
        item.articleUpdated = Int.now()
        try item.save {
            id in item.articleId = id as! Int
        }
        
        return GroupItem(id: item.articleId, barcode: barcode, product: product)
    }

    func update(id: Int, item: Article) throws {
        let connection = try ZenPostgres.pool.connect()
        defer { connection.disconnect() }

        let item = Article(connection: connection)
        try item.get(id)
        
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
                try item.save()
            }
        }
    }
    
    func delete(id: Int) throws {
        let item = Article()
        item.articleId = id
        try item.delete()
    }

    func addAttributeValue(item: ArticleAttributeValue) throws {
        try item.save {
            id in item.articleAttributeValueId = id as! Int
        }
    }
    
    func removeAttributeValue(id: Int) throws {
        let item = ArticleAttributeValue()
        item.articleAttributeValueId = id
        try item.delete()
    }
}
