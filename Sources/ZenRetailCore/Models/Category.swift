//
//  Category.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import PostgresNIO
import ZenPostgres
import ZenMWS

class Category: PostgresTable, Codable {
    
    public var categoryId : Int = 0
    public var categoryIsPrimary : Bool = false
    public var categoryName : String = ""
    public var categoryDescription: [Translation] = [Translation]()
    public var categoryMedia: Media? = nil
    public var categorySeo : Seo? = nil
    public var categoryCreated : Int = Int.now()
    public var categoryUpdated : Int = Int.now()
    
    private enum CodingKeys: String, CodingKey {
        case categoryId
        case categoryIsPrimary
        case categoryName
        case categoryDescription = "translations"
        case categoryMedia = "media"
        case categorySeo = "seo"
    }

    required init() {
        super.init()
        self.tableIndexes.append("categoryName")
    }

    override func decode(row: PostgresRow) {
        categoryId = row.column("categoryId")?.int ?? 0
        categoryIsPrimary = row.column("categoryIsPrimary")?.bool ?? true
        categoryName = row.column("categoryName")?.string ?? ""
        categoryDescription = try! row.column("categoryDescription")?.jsonb(as: [Translation].self) ?? categoryDescription
        categoryMedia = try! row.column("categoryMedia")?.jsonb(as: Media.self) ?? categoryMedia
        categorySeo = try! row.column("categorySeo")?.jsonb(as: Seo.self) ?? categorySeo
        categoryCreated = row.column("categoryCreated")?.int ?? 0
        categoryUpdated = row.column("categoryUpdated")?.int ?? 0
    }
    
    required init(from decoder: Decoder) throws {
        super.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)
        categoryId = try container.decode(Int.self, forKey: .categoryId)
        categoryIsPrimary = try container.decode(Bool.self, forKey: .categoryIsPrimary)
        categoryName = try container.decode(String.self, forKey: .categoryName)
        categoryDescription = try container.decodeIfPresent([Translation].self, forKey: .categoryDescription) ?? [Translation]()
        categoryMedia = try? container.decodeIfPresent(Media.self, forKey: .categoryMedia)
        categorySeo = try? container.decodeIfPresent(Seo.self, forKey: .categorySeo)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(categoryId, forKey: .categoryId)
        try container.encode(categoryIsPrimary, forKey: .categoryIsPrimary)
        try container.encode(categoryName, forKey: .categoryName)
        try container.encode(categoryDescription, forKey: .categoryDescription)
        try container.encodeIfPresent(categoryMedia, forKey: .categoryMedia)
        try container.encodeIfPresent(categorySeo, forKey: .categorySeo)
    }
    
    fileprivate func addCategory(name: String, description: String, isPrimary: Bool) throws {
        let translation = Translation()
        translation.country = "EN"
        translation.value = description
        
        let item = Category(connection: connection!)
        item.categoryName = name
        item.categoryIsPrimary = isPrimary
        item.categoryDescription.append(translation)
        if isPrimary {
            item.categorySeo = Seo()
            item.categorySeo!.permalink = item.categoryName.permalink()
        }
        item.categoryCreated = Int.now()
        item.categoryUpdated = Int.now()
        _ = try item.saveAsync().wait()
    }
    
    func setupMarketplace() throws {
        let rows: [Category] = try queryAsync(cursor: Cursor(limit: 1, offset: 0)).wait()
        if rows.count == 0 {
            for item in ClothingType.allCases {
                if item != .jewelry {
                    try addCategory(name: item.rawValue, description: "Clothing: \(item.rawValue)", isPrimary: true)
                }
            }
        }
    }
}
