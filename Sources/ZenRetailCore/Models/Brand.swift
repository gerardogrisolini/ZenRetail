//
//  Brand.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import PostgresClientKit
import ZenPostgres


class Brand: PostgresTable, Codable {
    
    public var brandId : Int = 0
    public var brandName : String = ""
    public var brandDescription: [Translation] = [Translation]()
    public var brandMedia: Media = Media()
    public var brandSeo : Seo = Seo()
    public var brandCreated : Int = Int.now()
    public var brandUpdated : Int = Int.now()
    
    private enum CodingKeys: String, CodingKey {
        case brandId
        case brandName
        case brandDescription = "translations"
        case brandMedia = "media"
        case brandSeo = "seo"
    }

    required init() {
        super.init()
        self.tableIndexes.append("brandName")
    }

    override func decode(row: Row) {
        if row.columns.count < 7 { return }

        brandId = (try? row.columns[0].int()) ?? 0
        brandName = (try? row.columns[1].string()) ?? ""
        let decoder = JSONDecoder()
        if let descriptions = row.columns[2].data {
            brandDescription = try! decoder.decode([Translation].self, from: descriptions)
        }
        if let media = row.columns[3].data {
            brandMedia = try! decoder.decode(Media.self, from: media)
        }
        if let seo = row.columns[4].data {
            brandSeo = try! decoder.decode(Seo.self, from: seo)
        }
        brandCreated = (try? row.columns[5].int()) ?? 0
        brandUpdated = (try? row.columns[6].int()) ?? 0
    }

    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        brandId = try container.decode(Int.self, forKey: .brandId)
        brandName = try container.decode(String.self, forKey: .brandName)
        brandDescription = try container.decodeIfPresent([Translation].self, forKey: .brandDescription) ?? [Translation]()
        brandMedia = try container.decodeIfPresent(Media.self, forKey: .brandMedia) ?? Media()
        brandSeo = try container.decodeIfPresent(Seo.self, forKey: .brandSeo) ?? Seo()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(brandId, forKey: .brandId)
        try container.encode(brandName, forKey: .brandName)
        try container.encode(brandDescription, forKey: .brandDescription)
        try container.encode(brandMedia, forKey: .brandMedia)
        try container.encode(brandSeo, forKey: .brandSeo)
    }
}
