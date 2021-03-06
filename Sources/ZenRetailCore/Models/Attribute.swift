//
//  Attribute.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import PostgresNIO
import ZenPostgres


class Attribute: PostgresTable, Codable {
    
    public var attributeId	: Int = 0
    public var attributeName : String = ""
    public var attributeTranslates: [Translation] = [Translation]()
    public var attributeCreated : Int = Int.now()
    public var attributeUpdated : Int = Int.now()
    
    private enum CodingKeys: String, CodingKey {
        case attributeId
        case attributeName
        case attributeTranslates = "translations"
    }

    required init() {
        super.init()
        self.tableIndexes.append("attributeName")
    }

    override func decode(row: PostgresRow) {
        attributeId = row.column("attributeId")?.int ?? 0
        attributeName = row.column("attributeName")?.string ?? ""
        attributeTranslates = try! row.column("attributeTranslates")?.jsonb(as: [Translation].self) ?? attributeTranslates
        attributeCreated = row.column("attributeCreated")?.int ?? 0
        attributeUpdated = row.column("attributeUpdated")?.int ?? 0
    }

    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        attributeId = try container.decode(Int.self, forKey: .attributeId)
        attributeName = try container.decode(String.self, forKey: .attributeName)
        attributeTranslates = try container.decodeIfPresent([Translation].self, forKey: .attributeTranslates) ?? [Translation]()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(attributeId, forKey: .attributeId)
        try container.encode(attributeName, forKey: .attributeName)
        try container.encode(attributeTranslates, forKey: .attributeTranslates)
    }

    fileprivate func addAttribute(name: String) -> EventLoopFuture<Int> {
        let item = Attribute(connection: connection!)
        item.attributeName = name
        item.attributeCreated = Int.now()
        item.attributeUpdated = Int.now()
        return item.save().flatMap { id -> EventLoopFuture<Int> in
            item.attributeId = id as! Int
            
            if name == "None" {
                let value = AttributeValue(connection: self.connection!)
                value.attributeId = item.attributeId
                value.attributeValueName = name
                value.attributeValueCreated = Int.now()
                value.attributeValueUpdated = Int.now()
                return value.save().map { id -> Int in
                    value.attributeValueId = id as! Int
                    return item.attributeId
                }
            }
            
            return self.connection!.eventLoop.future(item.attributeId)
        }
    }

    func setupMarketplace() -> EventLoopFuture<Void> {
        let query: EventLoopFuture<[Attribute]> = self.query(cursor: Cursor(limit: 1, offset: 0))
        return query.flatMap { rows -> EventLoopFuture<Void> in
            if rows.count == 0 {
                return self.addAttribute(name: "None").flatMap { _ -> EventLoopFuture<Void> in
                    return self.addAttribute(name: "Material").flatMap { _ -> EventLoopFuture<Void> in
                        return self.addAttribute(name: "Color").flatMap { _ -> EventLoopFuture<Void> in
                            return self.addAttribute(name: "Size").map { _ -> Void in }
                        }
                    }
                }
            }
            return self.connection!.eventLoop.future()
        }
    }
}
