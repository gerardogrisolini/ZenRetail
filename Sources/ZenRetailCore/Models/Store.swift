//
//  Store.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import NIOPostgres
import ZenPostgres


class Store: PostgresTable, Codable {
    
    public var storeId : Int = 0
    public var storeName : String = ""
    public var storeAddress	: String = ""
    public var storeCity : String = ""
    public var storeCountry	: String = ""
    public var storeZip	: String = ""
    public var storeCreated : Int = Int.now()
    public var storeUpdated : Int = Int.now()
    
    private enum CodingKeys: String, CodingKey {
        case storeId
        case storeName
        case storeAddress
        case storeCity
        case storeCountry
        case storeZip
        case storeUpdated = "updatedAt"
    }

    required init() {
        super.init()
        self.tableIndexes.append("storeName")
    }
    
    override func decode(row: PostgresRow) {
        storeId = row.column("storeId")?.int ?? 0
        storeName = row.column("storeName")?.string ?? ""
        storeAddress = row.column("storeAddress")?.string ?? ""
        storeCity = row.column("storeCity")?.string ?? ""
        storeCountry = row.column("storeCountry")?.string ?? ""
        storeZip = row.column("storeZip")?.string ?? ""
        storeCreated = row.column("storeCreated")?.int ?? 0
        storeUpdated = row.column("storeUpdated")?.int ?? 0
    }
}
