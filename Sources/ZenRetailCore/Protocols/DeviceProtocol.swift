//
//  DeviceProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 11/04/17.
//
//

protocol DeviceProtocol {
	
	func getAll(date: Int) throws -> [Device]
	
	func get(id: Int) throws -> Device?
	
	func add(item: Device) throws
	
	func update(id: Int, item: Device) throws
	
	func delete(id: Int) throws
}
