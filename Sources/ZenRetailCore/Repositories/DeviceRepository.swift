//
//  DeviceRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 11/04/17.
//
//

import Foundation
import ZenPostgres

struct DeviceRepository : DeviceProtocol {
	
	internal func getJoin() -> DataSourceJoin {
		return DataSourceJoin(
			table: "Store",
			onCondition: "Device.idStore = Store.storeId",
			direction: .LEFT
		)
	}

	func getAll(date: Int) throws -> [Device] {
		let items = Device()
		return try items.query(
			whereclause: "Device.deviceUpdated > $1", params: [date],
			orderby: ["Device.deviceId"],
			joins: [self.getJoin()]
		)
	}
	
	func get(id: Int) throws -> Device? {
		let item = Device()
        let rows: [Device] = try item.query(
			whereclause: "Device.deviceId = $1",
			params: [id],
			joins: [self.getJoin()]
		)
        return rows.first
	}
	
	func add(item: Device) throws {
		item.deviceCreated = Int.now()
		item.deviceUpdated = Int.now()
		try item.save {
			id in item.deviceId = id as! Int
		}
	}
	
	func update(id: Int, item: Device) throws {
		
		guard let current = try get(id: id) else {
			throw ZenError.recordNotFound
		}
		current.idStore = item.idStore
		current.deviceName = item.deviceName
		current.deviceToken = item.deviceToken
		current.deviceUpdated = Int.now()
		try current.save()
	}
	
	func delete(id: Int) throws {
		let item = Device()
		item.deviceId = id
		try item.delete()
	}
}
