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
    func make() -> EventLoopFuture<Void> {
        let sql = """
INSERT INTO "User" ("uniqueID", "username", "password", "firstname", "lastname", "email", "isAdmin")
VALUES ('\(uniqueID)','\(username)','\(password)','\(firstname)','\(lastname)','\(email)',true)
"""
        return self.sqlRowsAsync(sql).map { rows -> Void in
            ()
        }
    }
    
    
    /// Performs a find on supplied username, and matches hashed password
    open func get(usr: String, pwd: String) -> EventLoopFuture<Void> {
        return self.getAsync("username", usr).flatMapThrowing { () -> Void in
            if self.uniqueID.isEmpty {
                throw ZenError.recordNotFound
            }

            if pwd.encrypted != self.password {
                throw ZenError.passwordDoesNotMatch
            }
            return ()
        }
    }
    
    /// Returns a true / false depending on if the username exits in the database.
    func exists(_ un: String) -> EventLoopFuture<Bool> {
        let sql = querySQL(whereclause: "username = $1", params: [un], cursor: Cursor(limit: 1, offset: 0))
        return sqlRowsAsync(sql).map { rows -> Bool in
            if rows.count == 1 {
                self.decode(row: rows.first!)
                return true
            } else {
                return false
            }
        }
    }

	func setAdmin() -> EventLoopFuture<Void> {
        let query: EventLoopFuture<[User]> = queryAsync(whereclause: "isAdmin = $1", params: [true], cursor: Cursor(limit: 1, offset: 0))
        return query.flatMap { rows -> EventLoopFuture<Void> in
            if rows.count == 0 {
                return self.exists("admin").flatMap { exist -> EventLoopFuture<Void> in
                    if exist {
                        self.isAdmin = true
                        return self.updateAsync(cols: ["isAdmin"], params: [true], id: "uniqueID", value: self.uniqueID).map { count -> Void in
                            ()
                        }
                    } else {
                        self.uniqueID = UUID().uuidString
                        self.firstname = "Administrator"
                        self.username = "admin"
                        self.password = "admin".encrypted
                        self.isAdmin = true
                        return self.make()
                    }
                }
            }
            return self.connection!.eventLoop.future()
        }
	}
}


