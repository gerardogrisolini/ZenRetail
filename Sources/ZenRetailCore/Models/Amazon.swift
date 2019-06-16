//
//  Amazon.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 07/05/18.
//

import Foundation
import PostgresNIO
import ZenPostgres

class Amazon: Codable {
    
    public var endpoint: String = "mws-eu.amazonservices.com"
    public var marketplaceId: String = ""
    public var sellerId: String = ""
    public var accessKey: String = ""
    public var secretKey: String = ""
    public var authToken: String = ""
    public var userAgent: String = "ZenRetail/1.0 (Language=Swift/5.0)"
    
    func create(db: PostgresConnection) throws {
        let settings = Settings(db: db)
        let rows: [Settings] = try settings.query()
        if rows.count == 30 {
            let mirror = Mirror(reflecting: self)
            for case let (label?, value) in mirror.children {
                let setting = Settings(db: db)
                setting.key = label
                setting.value = "\(value)"
                try setting.save()
            }
        }
    }
    
    func save() throws {
        let db = try ZenPostgres.shared.connectAsync()
        defer { db.disconnect() }

        let settings = Settings(db: db)
        let mirror = Mirror(reflecting: self)
        for case let (label?, value) in mirror.children {
            _ = try settings.update(cols: ["value"], params: [value], id: "key", value: label)
        }
    }
    
    func select() throws {
        let rows: [Settings] = try Settings().query()
        let data = rows.reduce(into: [String: String]()) {
            $0[$1.key] = $1.value
        }
        
        endpoint = data["endpoint"] ?? ""
        marketplaceId = data["marketplaceId"] ?? ""
        sellerId = data["sellerId"] ?? ""
        accessKey = data["accessKey"] ?? ""
        secretKey = data["secretKey"] ?? ""
        authToken = data["authToken"] ?? ""
        userAgent = data["userAgent"] ?? ""
    }
}
