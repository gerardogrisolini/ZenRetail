//
//  TagValue.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 07/11/17.
//

import Foundation
import PostgresClientKit
import ZenPostgres


class TagValue: PostgresTable, Codable {
    
    public var tagValueId : Int = 0
    public var tagGroupId : Int = 0
    public var tagValueCode : String = ""
    public var tagValueName : String = ""
    public var tagValueTranslates: [Translation] = [Translation]()
    public var tagValueCreated : Int = Int.now()
    public var tagValueUpdated : Int = Int.now()
    
    private enum CodingKeys: String, CodingKey {
        case tagValueId
        case tagGroupId
        case tagValueCode
        case tagValueName
        case tagValueTranslates = "translations"
    }
    
    required init() {
        super.init()
        self.tableIndexes.append("tagValueCode")
    }
    
    override func decode(row: Row) {
        tagValueId = (try? row.columns[0].int()) ?? 0
        tagGroupId = (try? row.columns[1].int()) ?? 0
        tagValueCode = (try? row.columns[2].string()) ?? ""
        tagValueName = (try? row.columns[3].string()) ?? ""
        if let translates = row.columns[4].data {
            tagValueTranslates = try! JSONDecoder().decode([Translation].self, from: translates)
        }
        tagValueCreated = (try? row.columns[5].int()) ?? 0
        tagValueUpdated = (try? row.columns[6].int()) ?? 0
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tagValueId = try container.decode(Int.self, forKey: .tagValueId)
        tagGroupId = try container.decode(Int.self, forKey: .tagGroupId)
        tagValueCode = try container.decode(String.self, forKey: .tagValueCode)
        tagValueName = try container.decode(String.self, forKey: .tagValueName)
        tagValueTranslates = try container.decodeIfPresent([Translation].self, forKey: .tagValueTranslates) ?? [Translation]()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tagValueId, forKey: .tagValueId)
        try container.encode(tagGroupId, forKey: .tagGroupId)
        try container.encode(tagValueCode, forKey: .tagValueCode)
        try container.encode(tagValueName, forKey: .tagValueName)
        try container.encode(tagValueTranslates, forKey: .tagValueTranslates)
    }
}

