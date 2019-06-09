//
//  Settings.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 07/05/18.
//

import Foundation
import PostgresNIO
import ZenPostgres


class Settings: PostgresTable {
    public var id : Int = 0
    public var key : String = ""
    public var value : String = ""
    
    required init() {
        super.init()
        self.tableIndexes.append("key")
    }
    
    override func decode(row: PostgresRow) {
        id = row.column("id")?.int ?? 0
        key = row.column("key")?.string ?? ""
        value = row.column("value")?.string ?? ""
    }
}
