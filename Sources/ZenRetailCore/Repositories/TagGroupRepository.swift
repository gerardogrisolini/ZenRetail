//
//  TagGroupRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 07/11/17.
//

import Foundation
import ZenPostgres

struct TagGroupRepository : TagGroupProtocol {
    
    func getAll() throws -> [TagGroup] {
        let items = TagGroup()
        return try items.query()
    }
    
    func get(id: Int) throws -> TagGroup? {
        let item = TagGroup()
        try item.get(id)
        
        return item
    }
    
    func getValues(id: Int) throws -> [TagValue] {
        return try TagValue().query(whereclause: "tagGroupId = $1", params: [id])
    }
    
    func add(item: TagGroup) throws {
        item.tagGroupCreated = Int.now()
        item.tagGroupUpdated = Int.now()
        try item.save {
            id in item.tagGroupId = id as! Int
        }
    }
    
    func update(id: Int, item: TagGroup) throws {
        
        guard let current = try get(id: id) else {
            throw ZenError.noRecordFound
        }
        
        current.tagGroupName = item.tagGroupName
        current.tagGroupUpdated = Int.now()
        try current.save()
    }
    
    func delete(id: Int) throws {
        let item = TagGroup()
        item.tagGroupId = id
        try item.delete()
        
        _ = try item.sqlRows("DELETE FROM \"TagValue\" WHERE \"tagId\" = \(id)")
    }
}

