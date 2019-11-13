//
//  AttributeRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import NIO
import ZenPostgres

struct AttributeRepository : AttributeProtocol {

    func getAll() -> EventLoopFuture<[Attribute]> {
        return Attribute().queryAsync(orderby: ["attributeId"])
    }
    
    func get(id: Int) -> EventLoopFuture<Attribute> {
        let item = Attribute()
        return item.getAsync(id).map { () -> Attribute in
            return item
        }
    }
    
    func getValues(id: Int) -> EventLoopFuture<[AttributeValue]> {
        return AttributeValue().queryAsync(whereclause: "attributeId = $1", params: [id])
    }
    
    func add(item: Attribute) -> EventLoopFuture<Int> {
        item.attributeCreated = Int.now()
        item.attributeUpdated = Int.now()
        return item.saveAsync().map { id -> Int in
            item.attributeId = id as! Int
            return item.attributeId
        }
    }
    
    func update(id: Int, item: Attribute) -> EventLoopFuture<Bool> {
        item.attributeUpdated = Int.now()
        return item.saveAsync().map { id -> Bool in
            id as! Int > 0
        }
    }
    
    func delete(id: Int) -> EventLoopFuture<Bool> {
        return ZenPostgres.pool.connectAsync().flatMap { connection -> EventLoopFuture<Bool> in
            defer { connection.disconnect() }
            return AttributeValue(connection: connection).deleteAsync(key: "attributeId", value: id).flatMap { id -> EventLoopFuture<Bool> in
                return Attribute(connection: connection).deleteAsync(id)
            }
        }
    }
}
