//
//  Causal.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

import PostgresNIO
import ZenPostgres


class Causal: PostgresTable, PostgresJson {
    
    public var causalId : Int = 0
    public var causalName : String = ""
    public var causalQuantity : Int = 0
    public var causalBooked  : Int = 0
	public var causalIsPos : Bool = false
    public var causalCreated : Int = Int.now()
    public var causalUpdated : Int = Int.now()

    private enum CodingKeys: String, CodingKey {
        case causalId
        case causalName
        case causalQuantity
        case causalBooked
        case causalIsPos
        case causalUpdated = "updatedAt"
    }

    required init() {
        super.init()
        self.tableIndexes.append("causalName")
    }
    
    override func decode(row: PostgresRow) {
        causalId  = row.column("causalId")?.int ?? 0
        causalName = row.column("causalName")?.string ?? ""
        causalQuantity = row.column("causalQuantity")?.int ?? 0
        causalBooked = row.column("causalBooked")?.int ?? 0
        causalIsPos = row.column("causalIsPos")?.boolean ?? false
        causalCreated = row.column("causalCreated")?.int ?? 0
        causalUpdated = row.column("causalUpdated")?.int ?? 0
    }

    func setupDefaults() throws {
        let rows: [Causal] = try self.query(cursor: Cursor(limit: 1, offset: 0))
        if rows.count == 0 {
            let inventory = Causal()
            inventory.causalName = "Warehouse load"
            inventory.causalQuantity = 1
            inventory.causalIsPos = false
            inventory.causalUpdated = Int.now()
            try inventory.save()

            let discharge = Causal()
            discharge.causalName = "Warehouse discharge"
            discharge.causalQuantity = -1
            discharge.causalIsPos = false
            discharge.causalUpdated = Int.now()
            try discharge.save()

            let stockIn = Causal()
            stockIn.causalName = "Stock positive correction"
            stockIn.causalQuantity = 1
            stockIn.causalIsPos = false
            stockIn.causalUpdated = Int.now()
            try stockIn.save()

            let stockOut = Causal()
            stockOut.causalName = "Stock negative correction"
            stockOut.causalQuantity = -1
            stockOut.causalIsPos = false
            stockOut.causalUpdated = Int.now()
            try stockOut.save()

            let bookedIn = Causal()
            bookedIn.causalName = "Booked positive correction"
            bookedIn.causalBooked = 1
            bookedIn.causalIsPos = false
            bookedIn.causalUpdated = Int.now()
            try bookedIn.save()

            let bookedOut = Causal()
            bookedOut.causalName = "Booked negative correction"
            bookedOut.causalBooked = -1
            bookedOut.causalIsPos = false
            bookedOut.causalUpdated = Int.now()
            try bookedOut.save()

            let receipt = Causal()
            receipt.causalName = "Receipt"
            receipt.causalQuantity = -1
            receipt.causalIsPos = true
            receipt.causalUpdated = Int.now()
            try receipt.save()

            let cutomer = Causal()
            cutomer.causalName = "Customer order"
            cutomer.causalQuantity = -1
            cutomer.causalBooked = 1
            cutomer.causalIsPos = false
            cutomer.causalUpdated = Int.now()
            try cutomer.save()

            let causalOrder = Causal()
            causalOrder.causalName = "Supplier order"
            causalOrder.causalQuantity = 1
            causalOrder.causalIsPos = false
            causalOrder.causalUpdated = Int.now()
            try causalOrder.save()

            let barcode = Causal()
            barcode.causalName = "Print barcodes"
            barcode.causalIsPos = false
            barcode.causalUpdated = Int.now()
            try barcode.save()
        }
    }
}
