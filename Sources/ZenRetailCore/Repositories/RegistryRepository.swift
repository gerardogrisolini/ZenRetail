//
//  RegistryRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 13/03/17.
//
//

import Foundation
import NIO
import ZenPostgres

struct RegistryRepository : RegistryProtocol {

	func getAll(date: Int) -> EventLoopFuture<[Registry]> {
		return Registry().queryAsync(whereclause: "registryUpdated > $1", params: [date])
	}
	
	func get(id: Int) -> EventLoopFuture<Registry> {
		let item = Registry()
        return item.getAsync(id).map { () -> Registry in
            item
        }
	}
	
	func add(item: Registry) -> EventLoopFuture<Int> {
        if (item.registryPassword.isEmpty) {
            let password = UUID().uuidString
            item.registryPassword = password.encrypted
        }
		item.registryCreated = Int.now()
		item.registryUpdated = Int.now()
        
        return item.saveAsync().map { id -> Int in
            item.registryId = id as! Int
            return item.registryId
		}
	}
	
	func update(id: Int, item: Registry) -> EventLoopFuture<Bool> {
        return get(id: id).flatMap { current -> EventLoopFuture<Bool> in
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
            return current.saveAsync().map { id -> Bool in
                id as! Int > 0
            }
        }
	}
	
	func delete(id: Int) -> EventLoopFuture<Bool> {
		return Registry().deleteAsync(id)
	}
}
