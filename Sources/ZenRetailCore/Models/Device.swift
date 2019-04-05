//
//  Device.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 11/04/17.
//
//

import Foundation
import NIOPostgres
import ZenPostgres


class Device: PostgresTable, Codable {
	
	public var deviceId : Int = 0
	public var idStore : Int = 0
	public var deviceName : String = ""
	public var deviceToken : String = ""
	public var deviceCreated : Int = Int.now()
	public var deviceUpdated : Int = Int.now()
	
	public var _store: Store = Store()

    private enum CodingKeys: String, CodingKey {
        case deviceId
        case deviceName
        case deviceToken
        case _store = "store"
        case deviceUpdated = "updatedAt"
    }

    required init() {
        super.init()
        self.tableIndexes.append("deviceId")
        self.tableIndexes.append("deviceName")
    }
    
    override func decode(row: PostgresRow) {
		deviceId = row.column("deviceId")?.int ?? 0
		idStore = row.column("idStore")?.int ?? 0
		deviceName = row.column("deviceName")?.string ?? ""
		deviceToken = row.column("deviceToken")?.string ?? ""
		deviceCreated = row.column("deviceCreated")?.int ?? 0
		deviceUpdated = row.column("deviceUpdated")?.int ?? 0
        if idStore > 0 {
		    _store.decode(row: row)
        }
	}
	
	/// Performs a find on supplied deviceToken
	func get(token: String, name: String) throws {
        let sql = querySQL(
            whereclause: "deviceToken = $1 AND deviceName = $2",
            params: [token, name],
            cursor: Cursor(limit: 1, offset: 0)
        )
        let rows = try sqlRows(sql)
        if let row = rows.first {
            decode(row: row)
        } else {
            deviceName = name
            deviceToken = token
            try save()
        }
	}
}
