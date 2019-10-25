
//
//  Movement.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 28/02/17.
//
//

import Foundation
import PostgresClientKit
import ZenPostgres


struct ItemValue: Codable {
    public var value: String
}

class Movement: PostgresTable, Codable {
    
    public var movementId : Int = 0
    public var idInvoice : Int = 0
    public var movementNumber : Int = 0
    public var movementDate : Int = Int.now()
    public var movementDesc : String = ""
    public var movementNote : String = ""
    public var movementStatus : String = ""
    public var movementUser : String = ""
    public var movementDevice : String = ""
    public var movementStore : Store = Store()
    public var movementCausal : Causal = Causal()
    public var movementRegistry : Registry = Registry()
    public var movementTags : [Tag] = [Tag]()
    public var movementPayment : String = ""
    public var movementShipping : String = ""
    public var movementShippingCost : Double = 0
    public var movementAmount : Double = 0
    public var movementUpdated : Int = Int.now()
    
    public var _movementDate: String {
        return movementDate.formatDateShort()
    }

    public var _items : [MovementArticle] = [MovementArticle]()
    
    private enum CodingKeys: String, CodingKey {
        case movementId
        case movementNumber
        case movementDate
        case movementDesc
        case movementNote
        case movementStatus
        case movementUser
        case movementDevice
        case movementStore
        case movementCausal
        case movementRegistry
        case movementTags
        case movementPayment
        case movementShipping
        case movementShippingCost
        case movementAmount
        case _items = "movementItems"
        case movementUpdated = "updatedAt"
    }
    
    required init() {
        super.init()
    }
    
    override func decode(row: Row) {
        movementId = (try? row.columns[0].int()) ?? 0
        idInvoice = (try? row.columns[1].int()) ?? 0
        movementNumber = (try? row.columns[2].int()) ?? 0
        movementDate = (try? row.columns[3].int()) ?? 0
        movementDesc = (try? row.columns[4].string())  ?? ""
        movementNote = (try? row.columns[5].string()) ?? ""
        movementStatus = (try? row.columns[6].string()) ?? ""
        movementUser = (try? row.columns[7].string()) ?? ""
        movementDevice = (try? row.columns[8].string()) ?? ""
        let decoder = JSONDecoder()
        if let store = row.columns[9].data {
            movementStore = try! decoder.decode(Store.self, from: store)
        }
        if let causal = row.columns[10].data {
            movementCausal = try! decoder.decode(Causal.self, from: causal)
        }
        if let registry = row.columns[11].data {
            movementRegistry = try! decoder.decode(Registry.self, from: registry)
        }
        if let tags = row.columns[12].data {
            movementTags = try! decoder.decode([Tag].self, from: tags)
        }
        movementPayment = (try? row.columns[13].string()) ?? ""
        movementShipping = (try? row.columns[14].string()) ?? ""
        movementShippingCost = (try? row.columns[15].double()) ?? 0
        movementAmount = (try? row.columns[16].double()) ?? 0
        movementUpdated = (try? row.columns[17].int()) ?? 0
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        movementId = try container.decodeIfPresent(Int.self, forKey: .movementId) ?? 0
        movementNumber = try container.decode(Int.self, forKey: .movementNumber)
        movementDate = try container.decode(String.self, forKey: .movementDate).DateToInt()
        movementDesc = try container.decodeIfPresent(String.self, forKey: .movementDesc) ?? ""
        movementNote = try container.decode(String.self, forKey: .movementNote)
        movementStatus = try container.decode(String.self, forKey: .movementStatus)
        movementUser = try container.decodeIfPresent(String.self, forKey: .movementUser) ?? ""
        movementDevice = try container.decode(String.self, forKey: .movementDevice)
        movementStore = try container.decode(Store.self, forKey: .movementStore)
        movementCausal = try container.decode(Causal.self, forKey: .movementCausal)
        movementRegistry = try container.decodeIfPresent(Registry.self, forKey: .movementRegistry) ?? Registry()
        movementTags = try container.decodeIfPresent([Tag].self, forKey: .movementTags) ?? [Tag]()
        movementPayment = try container.decode(String.self, forKey: .movementPayment)
        movementShipping = try container.decodeIfPresent(String.self, forKey: .movementShipping) ?? ""
        movementShippingCost = try container.decodeIfPresent(Double.self, forKey: .movementShippingCost) ?? 0
        movementAmount = try container.decodeIfPresent(Double.self, forKey: .movementAmount) ?? 0
        _items = try container.decodeIfPresent([MovementArticle].self, forKey: ._items) ?? [MovementArticle]()
    }
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(movementId, forKey: .movementId)
        try container.encode(movementNumber, forKey: .movementNumber)
        try container.encode(_movementDate, forKey: .movementDate)
        try container.encode(movementDesc, forKey: .movementDesc)
        try container.encode(movementNote, forKey: .movementNote)
        try container.encode(movementStatus, forKey: .movementStatus)
        try container.encode(movementUser, forKey: .movementUser)
        try container.encode(movementDevice, forKey: .movementDevice)
        try container.encode(movementStore, forKey: .movementStore)
        try container.encode(movementCausal, forKey: .movementCausal)
        try container.encode(movementRegistry, forKey: .movementRegistry)
        try container.encode(movementTags, forKey: .movementTags)
        try container.encode(movementPayment, forKey: .movementPayment)
        try container.encode(movementShipping, forKey: .movementShipping)
        try container.encode(movementShippingCost, forKey: .movementShippingCost)
        try container.encode(movementAmount, forKey: .movementAmount)
        try container.encode(_items, forKey: ._items)
        try container.encode(movementUpdated, forKey: .movementUpdated)
    }
    
    func newNumber() throws {
        var sql = "SELECT COALESCE(MAX(\"movementNumber\"),0) AS counter FROM \"\(table)\"";
        if self.movementCausal.causalIsPos {
            sql += " WHERE \"movementDevice\" = '\(movementDevice)' AND to_char(to_timestamp(\"movementDate\" + extract(epoch from timestamp '2001-01-01 00:00:00')), 'YYYY-MM-DD') = '\(movementDate.formatDate(format: "yyyy-MM-dd"))'"
        }
        let getCount = try self.sqlRows(sql)
        self.movementNumber = (try getCount.first?.columns[0].int() ?? 0) + (self.movementCausal.causalIsPos ? 1 : 1000)
    }
    
    func getAmount() throws {
        let sql = "SELECT SUM(\"movementArticleQuantity\" * \"movementArticlePrice\") AS amount FROM \"MovementArticle\" WHERE \"movementId\" = \(movementId)"
        let getCount = try self.sqlRows(sql)
        self.movementAmount = (try getCount.first?.columns[0].double() ?? 0)
    }
}
