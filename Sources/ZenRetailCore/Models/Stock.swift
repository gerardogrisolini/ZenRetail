//
//  Stock.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 27/02/17.
//
//

import PostgresNIO
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
    
    override func decode(row: PostgresRow) {
        stockId = row.column("stockId")?.int ?? 0
        storeId = row.column("storeId")?.int ?? 0
        articleId = row.column("articleId")?.int ?? 0
        stockQuantity = row.column("stockQuantity")?.double ?? 0
        stockBooked = row.column("stockBooked")?.double ?? 0
        stockCreated = row.column("stockCreated")?.int ?? 0
        stockUpdated = row.column("stockUpdated")?.int ?? 0
    }
}
