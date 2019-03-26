//
//  TagValueProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 07/11/17.
//

protocol TagValueProtocol {
    
    func getAll() throws -> [TagValue]
    
    func get(id: Int) throws -> TagValue?
    
    func add(item: TagValue) throws
    
    func update(id: Int, item: TagValue) throws
    
    func delete(id: Int) throws
}

