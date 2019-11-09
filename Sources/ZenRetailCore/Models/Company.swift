//
//  Company.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 11/04/17.
//
//

import Foundation
import PostgresNIO
import ZenPostgres

class Company: Codable {
    public var companyName : String = ""
    public var companyWebsite : String = ""
    public var companyAddress : String = ""
    public var companyCity : String = ""
    public var companyZip : String = ""
    public var companyProvince : String = ""
    public var companyCountry : String = ""
    public var companyVatNumber : String = ""
    public var companyPhone : String = ""
    public var companyEmailInfo : String = ""
    public var companyEmailSales : String = ""
    public var companyEmailSupport : String = ""
    
    public var companyCurrency : String = ""
    public var companyUtc : String = ""
    public var companyLocales : [Translation] = [Translation]()

    public var homeFeatured : Bool = true
    public var homeNews : Bool = true
    public var homeDiscount : Bool = true
    public var homeCategory : Bool = true
    public var homeBrand : Bool = true

    public var homeSeo : Seo = Seo()
    public var homeContent: [Translation] = [Translation]()
    public var infoSeo : Seo = Seo()
    public var infoContent: [Translation] = [Translation]()

    public var barcodeCounterPublic : String = "688986544001"
    public var barcodeCounterPrivate : String = "616161616161"

    public var smtpHost : String = ""
    public var smtpSsl : Bool = false
    public var smtpUsername : String = ""
    public var smtpPassword : String = ""
    
    public var bankName : String = ""
    public var bankIban : String = ""
    public var paypalEnv : String = ""
    public var paypalSandbox : String = ""
    public var paypalProduction : String = ""
    public var cashOnDelivery : Bool = false
    
    public var shippingStandard : Bool = false
    public var shippingExpress : Bool = false

    func create() throws {
        let connection = try ZenPostgres.pool.connect()
        defer { connection.disconnect() }
        return try create(connection: connection)
    }
    
    func create(connection: PostgresConnection) throws {
        let encoder = JSONEncoder()
        let settings = Settings(connection: connection)
        let rows: [Settings] = try settings.query()
        if rows.count == 0 {
            let mirror = Mirror(reflecting: self)
            for case let (label?, value) in mirror.children {
                let setting = Settings(connection: connection)
                setting.key = label
                if value is [Translation] {
                    let jsonData = try encoder.encode(value as! [Translation])
                    setting.value = String(data: jsonData, encoding: .utf8)!
                } else if value is Seo {
                    let jsonData = try encoder.encode(value as! Seo)
                    setting.value = String(data: jsonData, encoding: .utf8)!
                } else {
                    setting.value = "\(value)"
                }
                try setting.save()
            }
        }
    }

    func save() throws {
        let connection = try ZenPostgres.pool.connect()
        defer { connection.disconnect() }
        return try save(connection: connection)
    }

    func save(connection: PostgresConnection) throws {
        let encoder = JSONEncoder()
        let settings = Settings(connection: connection)
        let mirror = Mirror(reflecting: self)
        for case let (label?, value) in mirror.children {
            if value is [Translation] {
                let jsonData = try encoder.encode(value as! [Translation])
                let valueString = String(data: jsonData, encoding: .utf8)!
                _ = try settings.update(cols: ["value"], params: [valueString], id: "key", value: label)
            } else if value is Seo {
                let jsonData = try encoder.encode(value as! Seo)
                let valueString = String(data: jsonData, encoding: .utf8)!
                _ = try settings.update(cols: ["value"], params: [valueString], id: "key", value: label)
            } else {
                _ = try settings.update(cols: ["value"], params: [value], id: "key", value: label)
            }
        }
    }
    
    func update(connection: PostgresConnection, key: String, value: String) throws {
        _ = try Settings(connection: connection).update(cols: ["value"], params: [value], id: "key", value: key)
    }
    
    func select() throws {
        let connection = try ZenPostgres.pool.connect()
        defer { connection.disconnect() }
        return try select(connection: connection)
    }
    
    func select(connection: PostgresConnection) throws {
        let settings = Settings(connection: connection)
        let rows: [Settings] = try settings.query()
        let data = rows.reduce(into: [String: String]()) {
            $0[$1.key] = $1.value
        }
        
        try loadData(data)
    }

    func selectAsync() -> EventLoopFuture<Void> {
        return ZenPostgres.pool.connectAsync().flatMap { conn -> EventLoopFuture<Void> in
            defer { conn.disconnect() }
            return self.selectAsync(connection: conn)
        }
    }

    func selectAsync(connection: PostgresConnection) -> EventLoopFuture<Void> {
        let query: EventLoopFuture<[Settings]> = Settings(connection: connection).queryAsync()
        return query.flatMapThrowing { rows -> Void in
            let data = rows.reduce(into: [String: String]()) {
                $0[$1.key] = $1.value
            }
            try self.loadData(data)
            return ()
        }
    }
    
    fileprivate func loadData(_ data: [String : String]) throws {
        let decoder = JSONDecoder()

        companyName = data["companyName"] ?? ""
        companyWebsite = data["companyWebsite"] ?? ""
        companyAddress = data["companyAddress"] ?? ""
        companyCity = data["companyCity"] ?? ""
        companyZip = data["companyZip"] ?? ""
        companyProvince = data["companyProvince"] ?? ""
        companyCountry = data["companyCountry"] ?? ""
        companyVatNumber = data["companyVatNumber"] ?? ""
        companyPhone = data["companyPhone"] ?? ""
        companyEmailInfo = data["companyEmailInfo"] ?? ""
        companyEmailSales = data["companyEmailSales"] ?? ""
        companyEmailSupport = data["companyEmailSupport"] ?? ""
        
        companyCurrency = data["companyCurrency"] ?? ""
        companyUtc = data["companyUtc"] ?? ""
        if let locales = data["companyLocales"],
            let data = locales.data(using: .utf8) {
            companyLocales = try decoder.decode([Translation].self, from: data)
        }
        
        homeFeatured = data["homeFeatured"]! == "true"
        homeNews = data["homeNews"]! == "true"
        homeDiscount = data["homeDiscount"]! == "true"
        homeCategory = data["homeCategory"]! == "true"
        homeBrand = data["homeBrand"]! == "true"
        
        if let seo = data["homeSeo"],
            let data = seo.data(using: .utf8) {
            homeSeo = try decoder.decode(Seo.self, from: data)
        }
        if let content = data["homeContent"],
            let data = content.data(using: .utf8) {
            homeContent = try decoder.decode([Translation].self, from: data)
        }
        if let seo = data["infoSeo"],
            let data = seo.data(using: .utf8) {
            infoSeo = try decoder.decode(Seo.self, from: data)
        }
        if let content = data["infoContent"],
            let data = content.data(using: .utf8) {
            infoContent = try decoder.decode([Translation].self, from: data)
        }
        
        barcodeCounterPublic = data["barcodeCounterPublic"] ?? barcodeCounterPublic
        barcodeCounterPrivate = data["barcodeCounterPrivate"] ?? barcodeCounterPrivate
        
        smtpHost = data["smtpHost"] ?? ""
        smtpSsl = data["smtpSsl"]! == "true"
        smtpUsername = data["smtpUsername"] ?? ""
        smtpPassword = data["smtpPassword"] ?? ""
        
        cashOnDelivery = data["cashOnDelivery"]! == "true"
        paypalEnv = data["paypalEnv"] ?? ""
        paypalSandbox = data["paypalSandbox"] ?? ""
        paypalProduction = data["paypalProduction"] ?? ""
        bankName = data["bankName"] ?? ""
        bankIban = data["bankIban"] ?? ""
        
        shippingStandard = data["shippingStandard"]! == "true"
        shippingExpress = data["shippingExpress"]! == "true"
    }
}
