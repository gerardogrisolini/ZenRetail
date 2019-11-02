//
//  ArticleAttributeValue.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import PostgresNIO
import ZenPostgres


class ArticleAttributeValue: PostgresTable, Codable {
    
    public var articleAttributeValueId : Int = 0
    public var articleId : Int = 0
    public var attributeValueId : Int = 0

    public var _attributeValue: AttributeValue = AttributeValue()

    private enum CodingKeys: String, CodingKey {
        case articleId
        case attributeValueId
        case articleAttributeValueMedia = "medias"
        case _attributeValue = "attributeValue"
    }
    
    override func decode(row: PostgresRow) {
        articleAttributeValueId = row.column("articleAttributeValueId")?.int ?? 0
        articleId = row.column("articleId")?.int ?? 0
        attributeValueId = row.column("attributeValueId")?.int ?? 0
    }
    
    required init() {
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        articleId = try container.decodeIfPresent(Int.self, forKey: .articleId) ?? 0
        attributeValueId = try container.decodeIfPresent(Int.self, forKey: .attributeValueId) ?? 0
        _attributeValue = try container.decodeIfPresent(AttributeValue.self, forKey: ._attributeValue) ?? AttributeValue()
}
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(attributeValueId, forKey: .attributeValueId)
    }
}
