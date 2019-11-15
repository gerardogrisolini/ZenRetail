//
//  TagGroup.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 07/11/17.
//

import Foundation
import PostgresNIO
import ZenPostgres


class TagGroup: PostgresTable, Codable {
    
    public var tagGroupId    : Int = 0
    public var tagGroupName : String = ""
    public var tagGroupTranslates: [Translation] = [Translation]()
    public var tagGroupCreated : Int = Int.now()
    public var tagGroupUpdated : Int = Int.now()
    
    public var _values: [TagValue] = [TagValue]()

    
    private enum CodingKeys: String, CodingKey {
        case tagGroupId
        case tagGroupName
        case tagGroupTranslates = "translations"
        case _values = "values"
    }
    
    required init() {
        super.init()
        self.tableIndexes.append("tagGroupName")
    }
    
    override func decode(row: PostgresRow) {
        tagGroupId = row.column("tagGroupId")?.int ?? 0
        tagGroupName = row.column("tagGroupName")?.string ?? ""
        tagGroupTranslates = try! row.column("tagGroupTranslates")?.jsonb(as: [Translation].self) ?? tagGroupTranslates
        tagGroupCreated = row.column("tagGroupCreated")?.int ?? 0
        tagGroupUpdated = row.column("tagGroupUpdated")?.int ?? 0
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tagGroupId = try container.decode(Int.self, forKey: .tagGroupId)
        tagGroupName = try container.decode(String.self, forKey: .tagGroupName)
        tagGroupTranslates = try container.decodeIfPresent([Translation].self, forKey: .tagGroupTranslates) ?? [Translation]()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tagGroupId, forKey: .tagGroupId)
        try container.encode(tagGroupName, forKey: .tagGroupName)
        try container.encode(tagGroupTranslates, forKey: .tagGroupTranslates)
        try container.encodeIfPresent(_values, forKey: ._values)
    }

    func setupMarketplace() -> EventLoopFuture<Void> {
        let query: EventLoopFuture<[TagGroup]> = self.query(
            whereclause: "tagGroupName = $1",
            params: ["Marketplace"],
            cursor: Cursor(limit: 1, offset: 0)
        )
        
        return query.flatMap { rows -> EventLoopFuture<Void> in
            if rows.count == 0 {
                self.tagGroupId = 0
                self.tagGroupName = "Marketplace"
                return self.save().flatMap { id -> EventLoopFuture<Void> in
                    self.tagGroupId = id as! Int

                    let tagValue = TagValue(connection: self.connection!)
                    tagValue.tagGroupId = self.tagGroupId
                    tagValue.tagValueCode = "MWS"
                    tagValue.tagValueName = "Amazon"
                    return tagValue.save().map { id -> Void in
                        tagValue.tagValueId = id as! Int
                        return ()
                    }
                }
            }
            return self.connection!.eventLoop.future()
        }
    }
}

