//
//  MovementArticleRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

import NIO
import PostgresNIO
import ZenPostgres


struct MovementArticleRepository : MovementArticleProtocol {

    func get(movementId: Int, connection: PostgresConnection) -> EventLoopFuture<[MovementArticle]> {
        return MovementArticle(connection: connection).query(
            whereclause: "movementId = $1",
            params: [movementId],
            orderby: ["movementArticleId"]
        )
    }
    
    func get(id: Int, connection: PostgresConnection) -> EventLoopFuture<MovementArticle> {
        let item = MovementArticle(connection: connection)
        return item.get(id).map { () -> MovementArticle in
            item
        }
    }
    
    func add(item: MovementArticle, price: String, connection: PostgresConnection) -> EventLoopFuture<Int> {
        let product = Product(connection: connection)
        
        return product.get(barcode: item.movementArticleBarcode).flatMap { () -> EventLoopFuture<Int> in
            if product.productId == 0 {
                return connection.eventLoop.future(error: ZenError.recordNotFound)
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
            item.connection = connection
            
            return item.save().map { id -> Int in
                item.movementArticleId = id as! Int
                return item.movementArticleId
            }
        }
    }
    
    func update(id: Int, item: MovementArticle, connection: PostgresConnection) -> EventLoopFuture<Bool> {
        item.connection = connection
        return item.update(
            cols: ["movementArticleQuantity", "movementArticleUpdated"],
            params: [item.movementArticleQuantity],
            id: "movementArticleId",
            value: id
        ).map { count -> Bool in
            count > 0
        }
    }
    
    func delete(id: Int, connection: PostgresConnection) -> EventLoopFuture<Bool> {
        return MovementArticle(connection: connection).delete(id)
    }
	
	func clone(sourceMovementId: Int, targetMovementId: Int, price: String, connection: PostgresConnection) -> EventLoopFuture<Void> {
        return self.get(movementId: sourceMovementId, connection: connection).flatMap { items -> EventLoopFuture<Void> in
            let promise = connection.eventLoop.makePromise(of: Void.self)
            
            let count = items.count - 1
            for (i, item) in items.enumerated() {
                item.movementArticleId = 0
                item.movementId = targetMovementId
                self.add(item: item, price: price, connection: connection).whenComplete { result in
                    if i == count {
                        switch result {
                        case .success(_):
                            promise.succeed(())
                        case .failure(let err):
                            promise.fail(err)
                        }
                    }
                }
            }
            
            return promise.futureResult
        }
	}
}
