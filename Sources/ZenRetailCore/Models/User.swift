//
//  Account.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 18/02/17.
//
//

import Foundation
import PostgresNIO
import ZenPostgres

/// Provides the Account structure for Perfect Turnstile
class User : PostgresTable, Codable {
    
    /// The User account's Unique ID
    public var uniqueID: String = ""
    
    /// The username with which the user will log in with
    public var username: String = ""
    
    /// The password to be set for the user
    public var password: String = ""
    
    /// Optional first name
    public var firstname: String = ""
    
    /// Optional last name
    public var lastname: String = ""
    
    /// Optional email
    public var email: String = ""
    
    /// Is Administrator
    public var isAdmin: Bool = false

    private enum CodingKeys: String, CodingKey {
        case uniqueID
        case username
        case password
        case firstname
        case lastname
        case email
        case isAdmin
    }

    required init() {
        super.init()
        self.tableIndexes.append(contentsOf: ["uniqueID", "username", "email"])
    }
    
    override func decode(row: PostgresRow) {
        uniqueID = row.column("uniqueID")?.string ?? ""
        username = row.column("username")?.string ?? ""
        password = row.column("password")?.string ?? ""
        firstname = row.column("firstname")?.string ?? ""
        lastname = row.column("lastname")?.string ?? ""
        email = row.column("email")?.string ?? ""
        isAdmin = row.column("isAdmin")?.bool ?? false
    }

    /// Shortcut to store the id
    public func id(_ newid: String) {
        uniqueID = newid
    }

    /// Forces a create with a hashed password
    func make() throws {
        let sql = """
INSERT INTO "User" ("uniqueID", "username", "password", "firstname", "lastname", "email", "isAdmin")
VALUES ('\(uniqueID)','\(username)','\(password)','\(firstname)','\(lastname)','\(email)',true)
"""
        do {
            _ = try self.sqlRows(sql)
        } catch {
            print(error)
        }
    }
    
    
    /// Performs a find on supplied username, and matches hashed password
    open func get(usr: String, pwd: String) throws {
        try self.get("username", usr)
        if uniqueID.isEmpty {
            throw ZenError.recordNotFound
        }

        if pwd.encrypted != password {
            throw ZenError.passwordDoesNotMatch
        }
    }
    
    /// Returns a true / false depending on if the username exits in the database.
    func exists(_ un: String) -> Bool {
        do {
            let sql = querySQL(whereclause: "username = $1", params: [un], cursor: Cursor(limit: 1, offset: 0))
            let rows = try sqlRows(sql)
            if rows.count == 1 {
                decode(row: rows.first!)
                return true
            } else {
                return false
            }
        } catch {
            print(error)
            return false
        }
    }

	func setAdmin() throws {
        let rows: [User] = try query(whereclause: "isAdmin = $1", params: [true], cursor: Cursor(limit: 1, offset: 0))
        if rows.count == 0 {
            if exists("admin") {
                isAdmin = true
                _ = try save()
            } else {
                uniqueID = UUID().uuidString
                firstname = "Administrator"
                username = "admin"
                password = "admin".encrypted
                isAdmin = true
                try make()
            }
        }
	}
}


