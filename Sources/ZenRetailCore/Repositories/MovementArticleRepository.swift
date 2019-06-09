//
//  MovementArticleRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

import PostgresNIO
import ZenPostgres


struct MovementArticleRepository : MovementArticleProtocol {

    func get(movementId: Int) throws -> [MovementArticle] {
        let items = MovementArticle()
        return try items.query(
            whereclause: "movementId = $1",
            params: [movementId],
            orderby: ["movementArticleId"]
        )
    }
    
    func get(id: Int) throws -> MovementArticle? {
        let item = MovementArticle()
		try item.get(id)
		
        return item
    }
    
    func add(item: MovementArticle, price: String) throws {
        let product = Product()
        try product.get(barcode: item.movementArticleBarcode)
        if product.productId == 0 {
            throw ZenError.noRecordFound
        }
        
        if price == "selling" {
            if let discount = product.productDiscount, discount.discountStartAt < Int.now()
                && discount.discountFinishAt > Int.now() {
                item.movementArticlePrice = discount.discountPrice
            } else {
                item.movementArticlePrice = product.productPrice.selling
            }
        }
        if price == "purchase" {
            item.movementArticlePrice = product.productPrice.purchase
        }
        
        item.movementArticleProduct = product
        item.movementArticleUpdated = Int.now()
        try item.save {
            id in item.movementArticleId = id as! Int
        }
    }
    
    func update(id: Int, item: MovementArticle) throws {
        
        guard let current = try get(id: id) else {
            throw ZenError.noRecordFound
        }
        
        current.movementArticleQuantity = item.movementArticleQuantity
        current.movementArticleUpdated = Int.now()
        try current.save()
    }
    
    func delete(id: Int) throws {
        let item = MovementArticle()
        item.movementArticleId = id
        try item.delete()
    }
	
	func clone(sourceMovementId: Int, targetMovementId: Int, price: String) throws {
        let items = try self.get(movementId: sourceMovementId)
		for item in items {
			item.movementArticleId = 0
			item.movementId = targetMovementId
            try self.add(item: item, price: price)
		}
	}
}
