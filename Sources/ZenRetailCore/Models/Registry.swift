//
//  Registry.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 13/03/17.
//
//

import Foundation
import PostgresClientKit
import ZenPostgres


class Registry: PostgresTable, PostgresJson {
	
    public var registryId : Int = 0
	public var registryName	: String = ""
	public var registryEmail : String = ""
    public var registryPassword : String = ""
	public var registryPhone : String = ""
	public var registryAddress : String = ""
	public var registryCity : String = ""
	public var registryZip : String = ""
    public var registryProvince : String = ""
	public var registryCountry : String = ""
	public var registryFiscalCode : String = ""
	public var registryVatNumber : String = ""
	public var registryCreated : Int = Int.now()
	public var registryUpdated : Int = Int.now()

    /// The User account's Unique ID
    public var uniqueID: String {
        return registryId.description
    }

    private enum CodingKeys: String, CodingKey {
        case registryId
        case registryName
        case registryEmail
        case registryPhone
        case registryAddress
        case registryCity
        case registryZip
        case registryProvince
        case registryCountry
        case registryFiscalCode
        case registryVatNumber
        case registryUpdated = "updatedAt"
    }
    
    required init() {
        super.init()
        self.tableIndexes.append("registryName")
        self.tableIndexes.append("registryEmail")
    }

    override func decode(row: Row) {
		registryId = (try? row.columns[0].int()) ?? 0
		registryName = (try? row.columns[1].string()) ?? ""
		registryEmail = (try? row.columns[2].string()) ?? ""
        registryPassword = (try? row.columns[3].string()) ?? ""
		registryPhone = (try? row.columns[4].string()) ?? ""
		registryAddress = (try? row.columns[5].string()) ?? ""
		registryCity = (try? row.columns[6].string()) ?? ""
		registryZip = (try? row.columns[7].string()) ?? ""
        registryProvince = (try? row.columns[8].string()) ?? ""
        registryCountry = (try? row.columns[9].string()) ?? ""
		registryFiscalCode = (try? row.columns[10].string()) ?? ""
		registryVatNumber = (try? row.columns[11].string()) ?? ""
		registryCreated = (try? row.columns[12].int()) ?? 0
		registryUpdated = (try? row.columns[13].int()) ?? 0
	}

    func get(email: String) throws {
        let sql = querySQL(
            whereclause: "registryEmail = $1",
            params: [email],
            cursor: CursorConfig(limit: 1, offset: 0)
        )
        let rows = try self.sqlRows(sql)
        if rows.count == 0 {
            throw ZenError.recordNotFound
        }
        decode(row: rows.first!)
    }
    
    /// Performs a find on supplied email, and matches hashed password
    open func get(email: String, pwd: String) throws {
        try get(email: email)
        
        if pwd.encrypted != registryPassword {
            throw ZenError.recordNotFound
        }
    }

    /// Returns a true / false depending on if the email exits in the database.
    func exists(_ email: String) -> Bool {
        do {
            try get(email: email)
            return true
        } catch {
            return false
        }
    }
}
