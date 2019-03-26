//
//  CausalProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

protocol CausalProtocol {
    
    func getAll(date: Int) throws -> [Causal]
    
    func get(id: Int) throws -> Causal?
    
    func add(item: Causal) throws
    
    func update(id: Int, item: Causal) throws
    
    func delete(id: Int) throws
}
