//
//  TagValueRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 07/11/17.
//

import NIO

struct TagValueRepository : TagValueProtocol {
    
    func getAll() -> EventLoopFuture<[TagValue]> {
        return TagValue().queryAsync(orderby: ["tagValueId"])
    }
    
    func get(id: Int) -> EventLoopFuture<TagValue> {
        let item = TagValue()
        return item.getAsync(id).map { () -> TagValue in
            item
        }
    }
    
    func add(item: TagValue) -> EventLoopFuture<Int> {
        item.tagValueCreated = Int.now()
        item.tagValueUpdated = Int.now()
        return item.saveAsync().map { id -> Int in
            item.tagValueId = id as! Int
            return item.tagValueId
        }
    }
    
    func update(id: Int, item: TagValue) -> EventLoopFuture<Bool> {
        item.tagValueId = id
        item.tagValueUpdated = Int.now()
        return item.saveAsync().map { id -> Bool in
            id as! Int > 0
        }
    }
    
    func delete(id: Int) -> EventLoopFuture<Bool> {
        return TagValue().deleteAsync(id)
    }
}

