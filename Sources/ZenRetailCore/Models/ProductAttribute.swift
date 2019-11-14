//
//  ProductAttribute.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import PostgresNIO
import ZenPostgres


class ProductAttribute: PostgresTable, Codable, Equatable {
    
    static func ==(lhs: ProductAttribute, rhs: ProductAttribute) -> Bool {
        return lhs.productAttributeId == rhs.productAttributeId
    }
    
    public var productAttributeId : Int = 0
    public var productId : Int = 0
    public var attributeId : Int = 0
    
    public var _attribute: Attribute = Attribute()
    public var _attributeValues: [ProductAttributeValue] = [ProductAttributeValue]()

    private enum CodingKeys: String, CodingKey {
        case productAttributeId
        case productId
        case attributeId
        case _attribute = "attribute"
        case _attributeValues = "attributeValues"
    }
    
    required init() {
        super.init()
    }
    
    override func decode(row: PostgresRow) {
        productAttributeId    = row.column("productAttributeId")?.int ?? 0
        productId = row.column("productId")?.int ?? 0
        attributeId = row.column("attributeId")?.int ?? 0
        _attribute.decode(row: row)
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        productId = try container.decodeIfPresent(Int.self, forKey: .productId) ?? 0
        _attribute = try container.decode(Attribute.self, forKey: ._attribute)
        attributeId = _attribute.attributeId
        _attributeValues = try container.decodeIfPresent([ProductAttributeValue].self, forKey: ._attributeValues) ?? [ProductAttributeValue]()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(productAttributeId, forKey: .productAttributeId)
        try container.encode(_attribute, forKey: ._attribute)
        try container.encode(_attributeValues, forKey: ._attributeValues)
    }
}
