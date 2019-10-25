//
//  Causal.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

import PostgresClientKit
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
    
    override func decode(row: Row) {
        causalId  = (try? row.columns[0].int()) ?? 0
        causalName = (try? row.columns[1].string()) ?? ""
        causalQuantity = (try? row.columns[2].int()) ?? 0
        causalBooked = (try? row.columns[2].int()) ?? 0
        causalIsPos = (try? row.columns[4].bool()) ?? false
        causalCreated = (try? row.columns[5].int()) ?? 0
        causalUpdated = (try? row.columns[6].int()) ?? 0
    }

    func setupDefaults() throws {
        let rows: [Causal] = try self.query(cursor: CursorConfig(limit: 1, offset: 0))
        if rows.count == 0 {
            let inventory = Causal(db: db!)
            inventory.causalName = "Warehouse load"
            inventory.causalQuantity = 1
            inventory.causalIsPos = false
            inventory.causalUpdated = Int.now()
            _ = try inventory.save()

            let discharge = Causal(db: db!)
            discharge.causalName = "Warehouse discharge"
            discharge.causalQuantity = -1
            discharge.causalIsPos = false
            discharge.causalUpdated = Int.now()
            _ = try discharge.save()

            let stockIn = Causal(db: db!)
            stockIn.causalName = "Stock positive correction"
            stockIn.causalQuantity = 1
            stockIn.causalIsPos = false
            stockIn.causalUpdated = Int.now()
            _ = try stockIn.save()

            let stockOut = Causal(db: db!)
            stockOut.causalName = "Stock negative correction"
            stockOut.causalQuantity = -1
            stockOut.causalIsPos = false
            stockOut.causalUpdated = Int.now()
            _ = try stockOut.save()

            let bookedIn = Causal(db: db!)
            bookedIn.causalName = "Booked positive correction"
            bookedIn.causalBooked = 1
            bookedIn.causalIsPos = false
            bookedIn.causalUpdated = Int.now()
            _ = try bookedIn.save()

            let bookedOut = Causal(db: db!)
            bookedOut.causalName = "Booked negative correction"
            bookedOut.causalBooked = -1
            bookedOut.causalIsPos = false
            bookedOut.causalUpdated = Int.now()
            _ = try bookedOut.save()

            let receipt = Causal(db: db!)
            receipt.causalName = "Receipt"
            receipt.causalQuantity = -1
            receipt.causalIsPos = true
            receipt.causalUpdated = Int.now()
            _ = try receipt.save()

            let cutomer = Causal(db: db!)
            cutomer.causalName = "Customer order"
            cutomer.causalQuantity = -1
            cutomer.causalBooked = 1
            cutomer.causalIsPos = false
            cutomer.causalUpdated = Int.now()
            _ = try cutomer.save()

            let causalOrder = Causal(db: db!)
            causalOrder.causalName = "Supplier order"
            causalOrder.causalQuantity = 1
            causalOrder.causalIsPos = false
            causalOrder.causalUpdated = Int.now()
            _ = try causalOrder.save()

            let barcode = Causal(db: db!)
            barcode.causalName = "Print barcodes"
            barcode.causalIsPos = false
            barcode.causalUpdated = Int.now()
            _ = try barcode.save()
        }
    }
}
