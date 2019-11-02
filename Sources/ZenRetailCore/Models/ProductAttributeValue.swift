//
//  ProductAttributeValue.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import PostgresNIO
import ZenPostgres


class ProductAttributeValue: PostgresTable, Codable, Equatable {
    
    static func ==(lhs: ProductAttributeValue, rhs: ProductAttributeValue) -> Bool {
        return lhs.productAttributeValueId == rhs.productAttributeValueId
    }
    
    public var productAttributeValueId	: Int = 0
    public var productAttributeId : Int = 0
    public var attributeValueId : Int = 0
    
    public var _attributeValue: AttributeValue = AttributeValue()

    private enum CodingKeys: String, CodingKey {
        case productAttributeId
        case _attributeValue = "attributeValue"
    }

    required init() {
        super.init()
    }
    
    override func decode(row: PostgresRow) {
        productAttributeValueId    = row.column("productAttributeValueId")?.int ?? 0
        productAttributeId = row.column("productAttributeId")?.int ?? 0
        attributeValueId = row.column("attributeValueId")?.int ?? 0
        _attributeValue.decode(row: row)
    }

    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        productAttributeId = try container.decodeIfPresent(Int.self, forKey: .productAttributeId) ?? 0
        _attributeValue = try container.decode(AttributeValue.self, forKey: ._attributeValue)
        attributeValueId = _attributeValue.attributeValueId
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_attributeValue, forKey: ._attributeValue)
    }
}
