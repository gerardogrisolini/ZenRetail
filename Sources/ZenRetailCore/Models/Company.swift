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
        let db = try ZenPostgres.shared.connect()
        defer { db.disconnect() }
        return try create(db: db)
    }
    
    func create(db: PostgresConnection) throws {
        let encoder = JSONEncoder()
        let settings = Settings(db: db)
        let rows: [Settings] = try settings.query()
        if rows.count == 0 {
            let mirror = Mirror(reflecting: self)
            for case let (label?, value) in mirror.children {
                let setting = Settings(db: db)
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
        let db = try ZenPostgres.shared.connect()
        defer { db.disconnect() }
        return try save(db: db)
    }

    func save(db: PostgresConnection) throws {
        let encoder = JSONEncoder()
        let settings = Settings(db: db)
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
    
    func select() throws {
        let db = try ZenPostgres.shared.connect()
        defer { db.disconnect() }
        return try select(db: db)
    }

    func select(db: PostgresConnection) throws {
        let decoder = JSONDecoder()
        let settings = Settings(db: db)
        let rows: [Settings] = try settings.query()
        let data = rows.reduce(into: [String: String]()) {
            $0[$1.key] = $1.value
        }
        
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
            homeSeo = try! decoder.decode(Seo.self, from: data)
        }
        if let content = data["homeContent"],
            let data = content.data(using: .utf8) {
            homeContent = try decoder.decode([Translation].self, from: data)
        }
        if let seo = data["infoSeo"],
            let data = seo.data(using: .utf8) {
            infoSeo = try! decoder.decode(Seo.self, from: data)
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
