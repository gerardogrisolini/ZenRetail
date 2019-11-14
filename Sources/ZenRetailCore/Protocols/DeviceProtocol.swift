//
//  DeviceProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 11/04/17.
//
//

import NIO

protocol DeviceProtocol {
	
	func getAll(date: Int) -> EventLoopFuture<[Device]>
	
	func get(id: Int) -> EventLoopFuture<Device>
	
	func add(item: Device) -> EventLoopFuture<Int>
	
	func update(id: Int, item: Device) -> EventLoopFuture<Bool>
	
	func delete(id: Int) -> EventLoopFuture<Bool>
}
