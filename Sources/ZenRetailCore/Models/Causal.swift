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
        causalIsPos = row.column("causalIsPos")?.bool ?? false
        causalCreated = row.column("causalCreated")?.int ?? 0
        causalUpdated = row.column("causalUpdated")?.int ?? 0
    }

    func setupDefaults() throws {
        let rows: [Causal] = try self.queryAsync(cursor: Cursor(limit: 1, offset: 0)).wait()
        if rows.count == 0 {
            let inventory = Causal(connection: connection!)
            inventory.causalName = "Warehouse load"
            inventory.causalQuantity = 1
            inventory.causalIsPos = false
            inventory.causalUpdated = Int.now()
            _ = try inventory.saveAsync().wait()

            let discharge = Causal(connection: connection!)
            discharge.causalName = "Warehouse discharge"
            discharge.causalQuantity = -1
            discharge.causalIsPos = false
            discharge.causalUpdated = Int.now()
            _ = try discharge.saveAsync().wait()

            let stockIn = Causal(connection: connection!)
            stockIn.causalName = "Stock positive correction"
            stockIn.causalQuantity = 1
            stockIn.causalIsPos = false
            stockIn.causalUpdated = Int.now()
            _ = try stockIn.saveAsync().wait()

            let stockOut = Causal(connection: connection!)
            stockOut.causalName = "Stock negative correction"
            stockOut.causalQuantity = -1
            stockOut.causalIsPos = false
            stockOut.causalUpdated = Int.now()
            _ = try stockOut.saveAsync().wait()

            let bookedIn = Causal(connection: connection!)
            bookedIn.causalName = "Booked positive correction"
            bookedIn.causalBooked = 1
            bookedIn.causalIsPos = false
            bookedIn.causalUpdated = Int.now()
            _ = try bookedIn.saveAsync().wait()

            let bookedOut = Causal(connection: connection!)
            bookedOut.causalName = "Booked negative correction"
            bookedOut.causalBooked = -1
            bookedOut.causalIsPos = false
            bookedOut.causalUpdated = Int.now()
            _ = try bookedOut.saveAsync().wait()

            let receipt = Causal(connection: connection!)
            receipt.causalName = "Receipt"
            receipt.causalQuantity = -1
            receipt.causalIsPos = true
            receipt.causalUpdated = Int.now()
            _ = try receipt.saveAsync().wait()

            let cutomer = Causal(connection: connection!)
            cutomer.causalName = "Customer order"
            cutomer.causalQuantity = -1
            cutomer.causalBooked = 1
            cutomer.causalIsPos = false
            cutomer.causalUpdated = Int.now()
            _ = try cutomer.saveAsync().wait()

            let causalOrder = Causal(connection: connection!)
            causalOrder.causalName = "Supplier order"
            causalOrder.causalQuantity = 1
            causalOrder.causalIsPos = false
            causalOrder.causalUpdated = Int.now()
            _ = try causalOrder.saveAsync().wait()

            let barcode = Causal(connection: connection!)
            barcode.causalName = "Print barcodes"
            barcode.causalIsPos = false
            barcode.causalUpdated = Int.now()
            _ = try barcode.saveAsync().wait()
        }
    }
}
