//
//  Brand.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import PostgresNIO
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

    override func decode(row: PostgresRow) {
        brandId = row.column("brandId")?.int ?? 0
        brandName = row.column("brandName")?.string ?? ""
        brandDescription = try! row.column("brandDescription")?.jsonb(as: [Translation].self) ?? brandDescription
        brandMedia = try! row.column("brandMedia")?.jsonb(as: Media.self) ?? brandMedia
        brandSeo = try! row.column("brandSeo")?.jsonb(as: Seo.self) ?? brandSeo
        brandCreated = row.column("brandCreated")?.int ?? 0
        brandUpdated = row.column("brandUpdated")?.int ?? 0
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
