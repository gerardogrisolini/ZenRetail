//
//  RegistryProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 13/03/17.
//
//

protocol RegistryProtocol {
	
	func getAll(date: Int) throws -> [Registry]
	
	func get(id: Int) throws -> Registry?
	
	func add(item: Registry) throws
	
	func update(id: Int, item: Registry) throws
	
	func delete(id: Int) throws
}
