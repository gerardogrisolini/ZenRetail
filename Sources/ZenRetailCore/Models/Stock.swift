//
//  Stock.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 27/02/17.
//
//

import PostgresClientKit
import ZenPostgres


class Stock: PostgresTable, Codable {
    
    public var stockId : Int = 0
    public var storeId : Int = 0
    public var articleId : Int = 0
    public var stockQuantity : Double = 0
    public var stockBooked : Double = 0
    public var stockCreated : Int = Int.now()
    public var stockUpdated : Int = Int.now()
    
    required init() {
        super.init()
    }
    
    override func decode(row: Row) {
        stockId = (try? row.columns[0].int()) ?? 0
        storeId = (try? row.columns[1].int()) ?? 0
        articleId = (try? row.columns[2].int()) ?? 0
        stockQuantity = (try? row.columns[3].double()) ?? 0
        stockBooked = (try? row.columns[4].double()) ?? 0
        stockCreated = (try? row.columns[5].int()) ?? 0
        stockUpdated = (try? row.columns[6].int()) ?? 0
    }
}
