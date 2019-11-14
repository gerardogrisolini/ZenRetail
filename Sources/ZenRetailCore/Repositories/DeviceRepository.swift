//
//  DeviceRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 11/04/17.
//
//

import Foundation
import NIO
import ZenPostgres

struct DeviceRepository : DeviceProtocol {
	
	internal func getJoin() -> DataSourceJoin {
		return DataSourceJoin(
			table: "Store",
			onCondition: "Device.idStore = Store.storeId",
			direction: .LEFT
		)
	}

	func getAll(date: Int) -> EventLoopFuture<[Device]> {
		let items = Device()
		return items.queryAsync(
			whereclause: "Device.deviceUpdated > $1", params: [date],
			orderby: ["Device.deviceId"],
			joins: [self.getJoin()]
		)
	}
	
	func get(id: Int) -> EventLoopFuture<Device> {
		let item = Device()
        let rows: EventLoopFuture<[Device]> = item.queryAsync(
			whereclause: "Device.deviceId = $1",
			params: [id],
			joins: [self.getJoin()]
        )
        return rows.flatMapThrowing { devices -> Device in
            if let device = devices.first {
                return device
            }
            throw ZenError.recordNotFound
        }
	}
	
	func add(item: Device) -> EventLoopFuture<Int> {
		item.deviceCreated = Int.now()
		item.deviceUpdated = Int.now()
		return item.saveAsync().map { id -> Int in
            item.deviceId = id as! Int
            return item.deviceId
		}
	}
	
	func update(id: Int, item: Device) -> EventLoopFuture<Bool> {
        item.deviceId = id
		item.deviceUpdated = Int.now()
        return item.saveAsync().map { id -> Bool in
            id as! Int > 0
        }
	}
	
	func delete(id: Int) -> EventLoopFuture<Bool> {
		return Device().deleteAsync(id)
	}
}
