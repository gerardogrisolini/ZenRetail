//
//  RegistryProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 13/03/17.
//
//

import NIO

protocol RegistryProtocol {
	
	func getAll(date: Int) -> EventLoopFuture<[Registry]>
	
	func get(id: Int) -> EventLoopFuture<Registry>
	
	func add(item: Registry) -> EventLoopFuture<Int>
	
	func update(id: Int, item: Registry) -> EventLoopFuture<Bool>
	
	func delete(id: Int) -> EventLoopFuture<Bool>
}
