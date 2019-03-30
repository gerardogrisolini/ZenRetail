//
//  RegistryRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 13/03/17.
//
//

import Foundation
import ZenPostgres

struct RegistryRepository : RegistryProtocol {

	func getAll(date: Int) throws -> [Registry] {
		let items = Registry()
		return try items.query(whereclause: "registryUpdated > $1", params: [date])
	}
	
	func get(id: Int) throws -> Registry? {
		let item = Registry()
		try item.get(id)
		
		return item
	}
	
	func add(item: Registry) throws {
        if (item.registryPassword.isEmpty) {
            let password = UUID().uuidString
            item.registryPassword = password.encrypted
        }
		item.registryCreated = Int.now()
		item.registryUpdated = Int.now()
		try item.save {
			id in item.registryId = id as! Int
		}
	}
	
	func update(id: Int, item: Registry) throws {
		
		guard let current = try get(id: id) else {
			throw ZenError.noRecordFound
		}
        if (item.registryPassword.count >= 8 && item.registryPassword.count <= 20) {
            current.registryPassword = item.registryPassword.encrypted
        }

		current.registryName = item.registryName
		current.registryEmail = item.registryEmail
		current.registryPhone = item.registryPhone
		current.registryAddress = item.registryAddress
		current.registryCity = item.registryCity
		current.registryZip = item.registryZip
        current.registryProvince = item.registryProvince
        current.registryCountry = item.registryCountry
		current.registryFiscalCode = item.registryFiscalCode
		current.registryVatNumber = item.registryVatNumber
		current.registryUpdated = Int.now()
		try current.save()
	}
	
	func delete(id: Int) throws {
		let item = Registry()
		item.registryId = id
		try item.delete()
	}
}
