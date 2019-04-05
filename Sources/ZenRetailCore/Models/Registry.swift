//
//  Registry.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 13/03/17.
//
//

import Foundation
import NIOPostgres
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

    override func decode(row: PostgresRow) {
		registryId = row.column("registryId")?.int ?? 0
		registryName = row.column("registryName")?.string ?? ""
		registryEmail = row.column("registryEmail")?.string ?? ""
        registryPassword = row.column("registryPassword")?.string ?? ""
		registryPhone = row.column("registryPhone")?.string ?? ""
		registryAddress = row.column("registryAddress")?.string ?? ""
		registryCity = row.column("registryCity")?.string ?? ""
		registryZip = row.column("registryZip")?.string ?? ""
        registryProvince = row.column("registryProvince")?.string ?? ""
        registryCountry = row.column("registryCountry")?.string ?? ""
		registryFiscalCode = row.column("registryFiscalCode")?.string ?? ""
		registryVatNumber = row.column("registryVatNumber")?.string ?? ""
		registryCreated = row.column("registryCreated")?.int ?? 0
		registryUpdated = row.column("registryUpdated")?.int ?? 0
	}

    func get(email: String) throws {
        let sql = querySQL(
            whereclause: "registryEmail = $1",
            params: [email],
            cursor: Cursor(limit: 1, offset: 0)
        )
        let rows = try self.sqlRows(sql)
        if rows.count == 0 {
            throw ZenError.noRecordFound
        }
        decode(row: rows.first!)
    }
    
    /// Performs a find on supplied email, and matches hashed password
    open func get(email: String, pwd: String) throws {
        try get(email: email)
        
        if pwd.encrypted != registryPassword {
            throw ZenError.noRecordFound
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
