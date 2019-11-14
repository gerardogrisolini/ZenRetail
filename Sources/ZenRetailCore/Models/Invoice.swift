//
//  Invoice.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 05/04/17.
//
//

import Foundation
import NIO
import PostgresNIO
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
    
    override func decode(row: PostgresRow) {
        invoiceId = row.column("invoiceId")?.int ?? 0
        invoiceNumber = row.column("invoiceNumber")?.int ?? 0
        invoiceDate = row.column("invoiceDate")?.int ?? 0
        invoiceRegistry = try! row.column("invoiceRegistry")?.jsonb(as: Registry.self) ?? invoiceRegistry
        invoicePayment = row.column("invoicePayment")?.string ?? ""
        invoiceNote = row.column("invoiceNote")?.string ?? ""
        invoiceUpdated = row.column("invoiceUpdated")?.int ?? 0

        let sql = """
SELECT SUM(a."movementArticleQuantity" * a."movementArticlePrice") AS amount
FROM "MovementArticle" AS a
INNER JOIN "Movement" AS b ON a."movementId" = b."movementId"
WHERE b."invoiceId" = \(invoiceId)
"""
        self.sqlRowsAsync(sql).whenSuccess { getCount in
            self._invoiceAmount = getCount.first?.column("amount")?.double ?? 0
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

	func makeNumber() -> EventLoopFuture<Void> {
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
        return self.sqlRowsAsync(sql).map { getCount -> Void in
            self.invoiceNumber += getCount.first?.column("counter")?.int ?? 0
        }
	}
}
