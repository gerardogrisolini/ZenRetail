//
//  PublicationRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import NIO

struct PublicationRepository : PublicationProtocol {

    func getAll() -> EventLoopFuture<[Publication]> {
        let items = Publication()
        return items.queryAsync(
            whereclause: "publicationStartAt <= $1 AND publicationFinishAt >= $1",
            params: [Int.now()])
    }
    
    func get(id: Int) -> EventLoopFuture<Publication> {
        let item = Publication()
        return item.getAsync(id).map { () -> Publication in
            item
        }
    }

    func getByProduct(productId: Int) -> EventLoopFuture<Publication> {
        let item = Publication()
        return item.getAsync("productId", productId).map { () -> Publication in
            item
        }
    }

    func add(item: Publication) -> EventLoopFuture<Int> {
        return item.saveAsync().map { id -> Int in
            item.publicationId = id as! Int
            return item.publicationId
        }
    }
    
    func update(id: Int, item: Publication) -> EventLoopFuture<Bool> {
        item.publicationId = id
		item.publicationUpdated = Int.now()
        return item.saveAsync().map { id -> Bool in
            id as! Int > 0
        }
    }
    
    func delete(id: Int) -> EventLoopFuture<Bool> {
        return Publication().deleteAsync(id)
    }
}
