//
//  StoreRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 27/02/17.
//
//

import NIOPostgres
import ZenPostgres


struct StoreRepository : StoreProtocol {

    func getAll() throws -> [Store] {
        let items = Store()
        return try items.query()
    }
    
    func get(id: Int) throws -> Store? {
        let item = Store()
		try item.get(id)
		
        return item
    }
    
    func add(item: Store) throws {
        item.storeCreated = Int.now()
        item.storeUpdated = Int.now()
        try item.save {
            id in item.storeId = id as! Int
        }
    }
    
    func update(id: Int, item: Store) throws {
        
        guard let current = try get(id: id) else {
            throw ZenError.noRecordFound
        }
        
        current.storeName = item.storeName
        current.storeAddress = item.storeAddress
        current.storeCity = item.storeCity
        current.storeCountry = item.storeCountry
        current.storeZip = item.storeZip
        current.storeUpdated = Int.now()
        try current.save()
    }
    
    func delete(id: Int) throws {
        let item = Store()
        item.storeId = id
        try item.delete()
    }
}
