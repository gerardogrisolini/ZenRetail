//
//  PublicationRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import NIOPostgres
import ZenPostgres


struct PublicationRepository : PublicationProtocol {

    func get() throws -> [Publication] {
        let items = Publication()
        return try items.query(
            whereclause: "publicationStartAt <= $1 AND publicationFinishAt >= $1",
            params: [Int.now()])
    }
    
    func get(id: Int) throws -> Publication? {
        let item = Publication()
		try item.get(id)

        return item.publicationId == 0 ? nil : item
    }

    func getByProduct(productId: Int) throws -> Publication? {
        let item = Publication()
        try item.get("productId", productId)
        
        if (item.publicationId == 0) {
            throw ZenError.noRecordFound
        }
        
        return item.publicationId == 0 ? nil : item
    }

    func add(item: Publication) throws {
        try item.save {
            id in item.publicationId = id as! Int
        }
    }
    
    func update(id: Int, item: Publication) throws {

        guard let current = try get(id: id) else {
            throw ZenError.noRecordFound
        }
        
        current.publicationFeatured = item.publicationFeatured
        current.publicationNew = item.publicationNew
        current.publicationStartAt = item.publicationStartAt
        current.publicationFinishAt = item.publicationFinishAt
		current.publicationUpdated = Int.now()
		try current.save()
    }
    
    func delete(id: Int) throws {
        let item = Publication()
        item.publicationId = id
        try item.delete()
    }
}
