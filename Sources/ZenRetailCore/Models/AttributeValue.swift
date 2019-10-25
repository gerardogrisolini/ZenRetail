//
//  AttributeValue.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import PostgresClientKit
import ZenPostgres


class AttributeValue: PostgresTable, Codable {
    
    public var attributeValueId : Int = 0
	public var attributeId : Int = 0
    public var attributeValueCode	: String = ""
    public var attributeValueName : String = ""
    public var attributeValueMedia: Media? = nil
    public var attributeValueTranslates: [Translation] = [Translation]()
    public var attributeValueCreated : Int = Int.now()
    public var attributeValueUpdated : Int = Int.now()
    
    private enum CodingKeys: String, CodingKey {
        case attributeValueId
        case attributeId
        case attributeValueCode
        case attributeValueName
        case attributeValueMedia = "media"
        case attributeValueTranslates = "translations"
    }

    required init() {
        super.init()
        self.tableIndexes.append("attributeValueCode")
        self.tableIndexes.append("attributeValueName")
    }
    
    override func decode(row: Row) {
        if row.columns.count != 8 { return }
        
        attributeValueId = (try? row.columns[0].int()) ?? 0
		attributeId = (try? row.columns[1].int()) ?? 0
        attributeValueCode = (try? row.columns[2].string()) ?? ""
        attributeValueName = (try? row.columns[3].string()) ?? ""
        let decoder = JSONDecoder()
        if let media = row.columns[4].data {
            attributeValueMedia = try! decoder.decode(Media.self, from: media)
        }
        if let translates = row.columns[5].data {
            attributeValueTranslates = try! decoder.decode([Translation].self, from: translates)
        }
        attributeValueCreated = (try? row.columns[6].int()) ?? 0
        attributeValueUpdated = (try? row.columns[7].int()) ?? 0
    }

    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        attributeValueId = try container.decode(Int.self, forKey: .attributeValueId)
        attributeId = try container.decode(Int.self, forKey: .attributeId)
        attributeValueCode = try container.decode(String.self, forKey: .attributeValueCode)
        attributeValueName = try container.decode(String.self, forKey: .attributeValueName)
        attributeValueMedia = try? container.decodeIfPresent(Media.self, forKey: .attributeValueMedia)
        attributeValueTranslates = try container.decodeIfPresent([Translation].self, forKey: .attributeValueTranslates) ?? [Translation]()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(attributeValueId, forKey: .attributeValueId)
        try container.encode(attributeId, forKey: .attributeId)
        try container.encode(attributeValueCode, forKey: .attributeValueCode)
        try container.encode(attributeValueName, forKey: .attributeValueName)
        try container.encodeIfPresent(attributeValueMedia, forKey: .attributeValueMedia)
        try container.encode(attributeValueTranslates, forKey: .attributeValueTranslates)
    }
}
