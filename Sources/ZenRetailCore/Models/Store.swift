//
//  Store.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import Foundation
import PostgresClientKit
import ZenPostgres


class Store: PostgresTable, PostgresJson {
    
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
    
    override func decode(row: Row) {
        storeId = (try? row.columns[0].int()) ?? 0
        storeName = (try? row.columns[1].string()) ?? ""
        storeAddress = (try? row.columns[2].string()) ?? ""
        storeCity = (try? row.columns[3].string()) ?? ""
        storeCountry = (try? row.columns[4].string()) ?? ""
        storeZip = (try? row.columns[5].string()) ?? ""
        storeCreated = (try? row.columns[6].int()) ?? 0
        storeUpdated = (try? row.columns[7].int()) ?? 0
    }
}
