//
//  AttributeValueRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import ZenPostgres

struct AttributeValueRepository : AttributeValueProtocol {

    func getAll() throws -> [AttributeValue] {
        let items = AttributeValue()
        return try items.query()
    }
    
    func get(id: Int) throws -> AttributeValue? {
        let item = AttributeValue()
		try item.get(id)
		
        return item
    }
    
    func add(item: AttributeValue) throws {
        item.attributeValueCreated = Int.now()
        item.attributeValueUpdated = Int.now()
        try item.save {
            id in item.attributeValueId = id as! Int
        }
    }
    
    func update(id: Int, item: AttributeValue) throws {

        guard let current = try get(id: id) else {
            throw ZenError.noRecordFound
        }
        
        current.attributeValueCode = item.attributeValueCode
        current.attributeValueName = item.attributeValueName
        current.attributeValueMedia = item.attributeValueMedia
        current.attributeValueTranslates = item.attributeValueTranslates
        current.attributeValueUpdated = Int.now()
        try current.save()
    }
    
    func delete(id: Int) throws {
        let item = AttributeValue()
        item.attributeValueId = id
        try item.delete()
    }
}
