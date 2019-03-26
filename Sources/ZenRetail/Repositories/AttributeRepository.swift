//
//  AttributeRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import ZenPostgres

struct AttributeRepository : AttributeProtocol {

    func getAll() throws -> [Attribute] {
        let items = Attribute()
        return try items.query()
    }
    
    func get(id: Int) throws -> Attribute? {
        let item = Attribute()
		try item.get(id)
		
        return item
    }
    
    func getValues(id: Int) throws -> [AttributeValue] {
        let items = AttributeValue()
        return try items.query(whereclause: "attributeId = $1",
                               params: [id],
                               cursor: Cursor(limit: 10000, offset: 0))
    }
    
    func add(item: Attribute) throws {
        item.attributeCreated = Int.now()
        item.attributeUpdated = Int.now()
        try item.save {
            id in item.attributeId = id as! Int
        }
    }
    
    func update(id: Int, item: Attribute) throws {
        
        guard let current = try get(id: id) else {
            throw ZenError.noRecordFound
        }
        
        current.attributeName = item.attributeName
        current.attributeTranslates = item.attributeTranslates
        current.attributeUpdated = Int.now()
        try current.save()
    }
    
    func delete(id: Int) throws {
        let item = Attribute()
        item.attributeId = id
        try item.delete()
        _ = try AttributeValue().delete(id: "attributeId", value: id)
    }
}
