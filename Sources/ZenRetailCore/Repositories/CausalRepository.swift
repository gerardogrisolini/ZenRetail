//
//  CausalRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

import ZenPostgres

struct CausalRepository : CausalProtocol {

    func getAll(date: Int) throws -> [Causal] {
        let items = Causal()
        return try items.query(whereclause: "causalUpdated > $1", params: [date])
    }
    
    func get(id: Int) throws -> Causal? {
        let item = Causal()
		try item.get(id)
		
        return item
    }
    
    func add(item: Causal) throws {
        item.causalCreated = Int.now()
        item.causalUpdated = Int.now()
        try item.save {
            id in item.causalId = id as! Int
        }
    }
    
    func update(id: Int, item: Causal) throws {
        
        guard let current = try get(id: id) else {
            throw ZenError.recordNotFound
        }
        
        current.causalName = item.causalName
        current.causalQuantity = item.causalQuantity
        current.causalBooked = item.causalBooked
		current.causalIsPos = item.causalIsPos
		current.causalUpdated = Int.now()
        try current.save()
    }
    
    func delete(id: Int) throws {
        let item = Causal()
        item.causalId = id
        try item.delete()
    }
}
