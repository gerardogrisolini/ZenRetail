//
//  ProductCategory.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import NIOPostgres
import ZenPostgres


class ProductCategory: PostgresTable, Codable {
    
    public var productCategoryId : Int = 0
    public var productId : Int = 0
    public var categoryId : Int = 0
    
    public var _category: Category = Category()

    private enum CodingKeys: String, CodingKey {
        case productId
        case _category = "category"
    }

    required init() {
        super.init()
    }
    
    override func decode(row: PostgresRow) {
        productCategoryId = row.column("productCategoryId")?.int ?? 0
        productId = row.column("productId")?.int ?? 0
        categoryId = row.column("categoryId")?.int ?? 0
        _category.decode(row:row)
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        productId = try container.decodeIfPresent(Int.self, forKey: .productId) ?? 0
        _category = try container.decode(Category.self, forKey: ._category)
        categoryId = _category.categoryId
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(productId, forKey: .productId)
        try container.encode(_category, forKey: ._category)
    }
}
