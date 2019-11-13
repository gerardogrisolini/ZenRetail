//
//  AttributeValueRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import NIO
import ZenPostgres

struct AttributeValueRepository : AttributeValueProtocol {

    func getAll() -> EventLoopFuture<[AttributeValue]> {
        return AttributeValue().queryAsync(orderby: ["attributeValueId"])
    }
    
    func get(id: Int) -> EventLoopFuture<AttributeValue> {
        let item = AttributeValue()
        return item.getAsync(id).map { () -> AttributeValue in
            return item
        }
    }
    
    func add(item: AttributeValue) -> EventLoopFuture<Int> {
        item.attributeValueCreated = Int.now()
        item.attributeValueUpdated = Int.now()
        return item.saveAsync().map { id -> Int in
            item.attributeValueId = id as! Int
            return item.attributeValueId
        }
    }
    
    func update(id: Int, item: AttributeValue) -> EventLoopFuture<Bool> {
        item.attributeValueUpdated = Int.now()
        return item.saveAsync().map { id -> Bool in
            id as! Int > 0
        }
    }
    
    func delete(id: Int) -> EventLoopFuture<Bool> {
        return AttributeValue().deleteAsync(id)
    }
}
