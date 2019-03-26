//
//  BrandProtocol.swift
//  PerfectTurnstilePostgreSQLDemo
//
//  Created by Gerardo Grisolini on 16/02/17.
//
//

protocol BrandProtocol {
    
    func getAll() throws -> [Brand]
    
    func get(id: Int) throws -> Brand?
    
    func add(item: Brand) throws
    
    func update(id: Int, item: Brand) throws
    
    func delete(id: Int) throws
}
