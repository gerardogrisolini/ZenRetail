//
//  Device.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 11/04/17.
//
//

import Foundation
import PostgresClientKit
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
    
    override func decode(row: Row) {
		deviceId = (try? row.columns[0].int()) ?? 0
		idStore = (try? row.columns[1].int()) ?? 0
		deviceName = (try? row.columns[2].string()) ?? ""
		deviceToken = (try? row.columns[3].string()) ?? ""
		deviceCreated = (try? row.columns[4].int()) ?? 0
		deviceUpdated = (try? row.columns[5].int()) ?? 0
        if idStore > 0 {
		    _store.decode(row: row)
        }
	}
	
	/// Performs a find on supplied deviceToken
	func get(token: String, name: String) throws {
        let sql = querySQL(
            whereclause: "deviceToken = $1 AND deviceName = $2",
            params: [token, name],
            cursor: CursorConfig(limit: 1, offset: 0)
        )
        let rows = try sqlRows(sql)
        if let row = rows.first {
            decode(row: row)
        } else {
            deviceName = name
            deviceToken = token
            _ = try save()
        }
	}
}
