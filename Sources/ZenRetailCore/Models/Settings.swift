//
//  Settings.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 07/05/18.
//

import Foundation
import PostgresClientKit
import ZenPostgres


class Settings: PostgresTable {
    public var id : Int = 0
    public var key : String = ""
    public var value : String = ""
    
    required init() {
        super.init()
        self.tableIndexes.append("key")
    }
    
    override func decode(row: Row) {
        id = (try? row.columns[0].int()) ?? 0
        key = (try? row.columns[1].string()) ?? ""
        value = (try? row.columns[2].string()) ?? ""
    }
}
