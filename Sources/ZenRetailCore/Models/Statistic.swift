//
//  Statistic.swift
//  macWebretail
//
//  Created by Gerardo Grisolini on 20/06/17.
//  Copyright © 2017 Gerardo Grisolini. All rights reserved.
//

import PostgresClientKit
import ZenPostgres


class Statistics: Codable {
    
    public var labels : [String] = [String]()
    public var datasets: [Statistic] = [Statistic]()
}

class Statistic: Codable {
    
    public var label : String = ""
    public var data: [Double] = [Double]()
    public var backgroundColor: [String] = [String]()
    public var borderColor : String = ""
    public var fill : Bool = false
}

class StatisticItem: PostgresTable, Codable {
    
    public var id : Int = 0
    public var label : String = ""
    public var value : Double = 0
    
    required init() {
        super.init()
    }
    
    override func decode(row: Row) {
        id = (try? row.columns[0].int()) ?? 0
        label = (try? row.columns[1].string()) ?? ""
        value = (try? row.columns[2].double()) ?? 0
    }
}

