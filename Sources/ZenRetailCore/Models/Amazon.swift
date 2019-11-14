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
    public var userAgent: String = "ZenRetail/1.0 (Language=Swift/5.1)"
    
    func createAsync(connection: PostgresConnection) -> EventLoopFuture<Void> {
        let settings = Settings(connection: connection)
        let query: EventLoopFuture<[Settings]> = settings.queryAsync()
        return query.map { rows -> Void in
            if rows.count == 30 {
                let mirror = Mirror(reflecting: self)
                for case let (label?, value) in mirror.children {
                    let setting = Settings(connection: connection)
                    setting.key = label
                    setting.value = "\(value)"
                    setting.saveAsync().whenComplete { _ in }
                }
            }
        }
    }
    
    func selectAsync() -> EventLoopFuture<Void> {
        let query: EventLoopFuture<[Settings]> = Settings().queryAsync()
        return query.map { rows -> Void in
            let data = rows.reduce(into: [String: String]()) {
                $0[$1.key] = $1.value
            }
            
            self.endpoint = data["endpoint"] ?? ""
            self.marketplaceId = data["marketplaceId"] ?? ""
            self.sellerId = data["sellerId"] ?? ""
            self.accessKey = data["accessKey"] ?? ""
            self.secretKey = data["secretKey"] ?? ""
            self.authToken = data["authToken"] ?? ""
            self.userAgent = data["userAgent"] ?? ""
        }
    }
    
    func saveAsync(connection: PostgresConnection) -> EventLoopFuture<Void> {
        let promise = connection.eventLoop.makePromise(of: Void.self)
        
        let settings = Settings(connection: connection)
        let mirror = Mirror(reflecting: self)
        var index = 0
        let count = mirror.children.count
        for case (let label?, let value) in mirror.children {
           settings.updateAsync(cols: ["value"], params: [value], id: "key", value: label).whenComplete { result in
                index += 1
                if index == count {
                    switch result {
                    case .success(_):
                        promise.succeed(())
                    case .failure(let err):
                        promise.fail(err)
                    }
                }
            }
        }

        return promise.futureResult
    }
    
    /*
    func create(connection: PostgresConnection) throws {
        let settings = Settings(connection: connection)
        let rows: [Settings] = try settings.query()
        if rows.count == 30 {
            let mirror = Mirror(reflecting: self)
            for case let (label?, value) in mirror.children {
                let setting = Settings(connection: connection)
                setting.key = label
                setting.value = "\(value)"
                try setting.save()
            }
        }
    }
    
    func save() throws {
        let connection = try ZenPostgres.pool.connect()
        defer { connection.disconnect() }

        let settings = Settings(connection: connection)
        let mirror = Mirror(reflecting: self)
        for case let (label?, value) in mirror.children {
            _ = try settings.update(cols: ["value"], params: [value], id: "key", value: label)
        }
    }
    */
}
