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
        if let translates = row.column("attributeTranslates")?.data {
            attributeTranslates = try! JSONDecoder().decode([Translation].self, from: translates)
        }
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

    fileprivate func addAttribute(name: String) throws {
        let item = Attribute(db: db!)
        item.attributeName = name
        item.attributeCreated = Int.now()
        item.attributeUpdated = Int.now()
        try item.save {
            id in item.attributeId = id as! Int
        }
        if name == "None" {
            let value = AttributeValue(db: db!)
            value.attributeId = item.attributeId
            value.attributeValueName = name
            value.attributeValueCreated = Int.now()
            value.attributeValueUpdated = Int.now()
            try value.save {
                id in value.attributeValueId = id as! Int
            }
        }
    }

    func setupMarketplace() throws {
        let rows: [Attribute] = try query(cursor: Cursor(limit: 1, offset: 0))
        if rows.count == 0 {
            try addAttribute(name: "None")
            try addAttribute(name: "Material")
            try addAttribute(name: "Color")
            try addAttribute(name: "Size")
        }
    }
}
