//
//  CausalRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

import NIO
import ZenPostgres

struct CausalRepository : CausalProtocol {

    func getAll(date: Int) -> EventLoopFuture<[Causal]> {
        return Causal().query(whereclause: "causalUpdated > $1", params: [date])
    }
    
    func get(id: Int) -> EventLoopFuture<Causal> {
        let item = Causal()
        return item.get(id).map { () -> Causal in
            item
        }
    }
    
    func add(item: Causal) -> EventLoopFuture<Int> {
        item.causalCreated = Int.now()
        item.causalUpdated = Int.now()
        return item.save().map { id -> Int in
            item.causalId = id as! Int
            return item.causalId
        }
    }
    
    func update(id: Int, item: Causal) -> EventLoopFuture<Bool> {
        item.causalUpdated = Int.now()
        return item.save().map { id -> Bool in
            id as! Int > 0
        }
    }
    
    func delete(id: Int) -> EventLoopFuture<Bool> {
        return Causal().delete(id)
    }
}
