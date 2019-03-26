//
//  AccessTokenStore.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 26/02/17.
//
//

import Foundation
import NIOPostgres
import ZenPostgres


/// Class for handling the tokens that are used for JSON API and Web authentication
class AccessTokenStore : PostgresTable, Codable {
    
    /// The token itself.
    public var token: String = ""
    
    /// The userid relates to the Users object UniqueID
    public var userId: String = ""
    
    /// Integer relaing to the created date/time
    public var created: Int = 0
    
    /// Integer relaing to the last updated date/time
    public var updated: Int = 0
    
    /// Idle period specified when token was created
    public var idle: Int = 86400 // 86400 seconds = 1 day
    
    required init() {
        super.init()
        self.tableIndexes.append("token")
    }
    
    /// Set incoming data from database to object
    override func decode(row: PostgresRow) {
        if let val = row.column("token")?.string { token = val }
        if let val = row.column("userId")?.string { userId = val }
        if let val = row.column("created")?.int { created = val }
        if let val = row.column("updated")?.int { updated = val }
        if let val = row.column("idle")?.int { idle = val }
    }
    
    /// Checks to see if the token is active
    /// Upticks the updated int to keep it alive.
    public func check() -> Bool? {
        if (updated + idle) < Int.now() { return false } else {
            do {
                updated = Int.now()
                try save()
            } catch {
                print(error)
            }
            return true
        }
    }
    
    /// Triggers creating a new token.
    public func new(_ u: String) -> String {
		do {
			token = ""
            try self.get("userId", u)
			if userId.isEmpty {
				token = UUID().uuidString
				userId = u
				created = Int.now()
				try create()
			} else {
				updated = Int.now()
				try save()
			}
        } catch {
            print(error)
        }
        return token
    }
    
//    /// Performs a find on supplied token
//    func get(token: String) {
//        do {
//            try self.query(whereclause: "token = $1", params: [token], cursor: StORMCursor(limit: 1, offset: 0))
//        } catch {
//            LogFile.error("\(error)")
//        }
//    }
}
