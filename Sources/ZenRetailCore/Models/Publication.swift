//
//  Publication.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import PostgresClientKit
import ZenPostgres


class Publication: PostgresTable, Codable {
    
    public var publicationId : Int = 0
    public var productId : Int = 0
    public var publicationFeatured : Bool = false
    public var publicationNew : Bool = false
    public var publicationStartAt : Int = 0
    public var publicationFinishAt : Int = 0
	public var publicationUpdated : Int = Int.now()

    public var _publicationStartAt: String {
        return publicationStartAt.formatDateShort()
    }
    
    public var _publicationFinishAt: String {
        return publicationFinishAt.formatDateShort()
    }

    private enum CodingKeys: String, CodingKey {
        case publicationId
        case productId
        case publicationFeatured
        case publicationNew
        case publicationStartAt
        case publicationFinishAt
    }
    
    required init() {
        super.init()
    }
    
    override func decode(row: Row) {
        publicationId = (try? row.columns[0].int()) ?? 0
        productId = (try? row.columns[1].int()) ?? 0
		publicationFeatured = (try? row.columns[2].bool()) ?? false
        publicationStartAt = (try? row.columns[3].int()) ?? 0
        publicationFinishAt = (try? row.columns[4].int()) ?? 0
		publicationUpdated = (try? row.columns[5].int()) ?? 0
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        publicationId = try container.decode(Int.self, forKey: .publicationId)
        productId = try container.decode(Int.self, forKey: .productId)
        publicationFeatured = try container.decode(Bool.self, forKey: .publicationFeatured)
        publicationNew = try container.decode(Bool.self, forKey: .publicationNew)
        publicationStartAt = try container.decode(String.self, forKey: .publicationStartAt).DateToInt()
        publicationFinishAt = try container.decode(String.self, forKey: .publicationFinishAt).DateToInt()
    }
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(publicationId, forKey: .publicationId)
        try container.encode(productId, forKey: .productId)
        try container.encode(publicationFeatured, forKey: .publicationFeatured)
        try container.encode(publicationNew, forKey: .publicationNew)
        try container.encode(_publicationStartAt, forKey: .publicationStartAt)
        try container.encode(_publicationFinishAt, forKey: .publicationFinishAt)
    }
}
