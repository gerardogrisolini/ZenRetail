//
//  Invoice.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 05/04/17.
//
//

import Foundation
import PostgresClientKit
import ZenPostgres


class Invoice: PostgresTable, Codable {
	
	public var invoiceId : Int = 0
	public var invoiceNumber : Int = 0
	public var invoiceDate : Int = Int.now()
	public var invoiceRegistry : Registry = Registry()
	public var invoicePayment : String = ""
	public var invoiceNote : String = ""
	public var invoiceUpdated : Int = Int.now()
	
    public var _invoiceAmount : Double = 0
    public var _invoiceDate: String {
        return invoiceDate.formatDateShort()
    }
    
    private enum CodingKeys: String, CodingKey {
        case invoiceId
        case invoiceNumber
        case invoiceDate
        case invoiceRegistry
        case invoicePayment
        case invoiceNote
        case _invoiceAmount = "invoiceAmount"
    }

    required init() {
        super.init()
    }
    
    override func decode(row: Row) {
		invoiceId = (try? row.columns[0].int()) ?? 0
		invoiceNumber = (try? row.columns[1].int()) ?? 0
		invoiceDate = (try? row.columns[2].int()) ?? 0
		if let registry = row.columns[3].data {
            invoiceRegistry = try! JSONDecoder().decode(Registry.self, from: registry)
        }
		invoicePayment = (try? row.columns[4].string()) ?? ""
		invoiceNote = (try? row.columns[5].string()) ?? ""
		invoiceUpdated = (try? row.columns[6].int()) ?? 0

        let sql = """
SELECT SUM(a."movementArticleQuantity" * a."movementArticlePrice") AS amount
FROM "MovementArticle" AS a
INNER JOIN "Movement" AS b ON a."movementId" = b."movementId"
WHERE b."invoiceId" = \(invoiceId)
"""
        do {
            let getCount = try self.sqlRows(sql)
            _invoiceAmount = (try? getCount.first?.columns[0].double()) ?? 0
        } catch {
            print(error)
        }
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        invoiceId = try container.decode(Int.self, forKey: .invoiceId)
        invoiceNumber = try container.decode(Int.self, forKey: .invoiceNumber)
        invoiceDate = try container.decode(String.self, forKey: .invoiceDate).DateToInt()
        invoiceRegistry = try container.decodeIfPresent(Registry.self, forKey: .invoiceRegistry) ?? Registry()
        invoicePayment = try container.decode(String.self, forKey: .invoicePayment)
        invoiceNote = try container.decode(String.self, forKey: .invoiceNote)
        _invoiceAmount = try container.decode(Double.self, forKey: ._invoiceAmount)
    }
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(invoiceId, forKey: .invoiceId)
        try container.encode(invoiceNumber, forKey: .invoiceNumber)
        try container.encode(_invoiceDate, forKey: .invoiceDate)
        try container.encode(invoiceRegistry, forKey: .invoiceRegistry)
        try container.encode(invoicePayment, forKey: .invoicePayment)
        try container.encode(invoiceNote, forKey: .invoiceNote)
        try container.encode(_invoiceAmount, forKey: ._invoiceAmount)
    }

	func makeNumber() throws {
		let now = Date()
		let calendar = Calendar.current
		
		var dateComponents = DateComponents()
		dateComponents.year = calendar.component(.year, from: now)
		dateComponents.month = 1
		dateComponents.day = 1
		dateComponents.timeZone = TimeZone(abbreviation: "UTC")
		dateComponents.hour = 0
		dateComponents.minute = 0

		let date = calendar.date(from: dateComponents)!
		
		self.invoiceNumber = 1
		let sql = "SELECT COALESCE(MAX(\"invoiceNumber\"),0) AS counter FROM \"\(table)\" WHERE \"invoiceDate\" > \(date.timeIntervalSinceReferenceDate)"
		let getCount = try self.sqlRows(sql)
		self.invoiceNumber += (try? getCount.first?.columns[0].int()) ?? 0
	}
}
