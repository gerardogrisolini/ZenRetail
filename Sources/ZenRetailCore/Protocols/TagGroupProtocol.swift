//
//  TarGroupProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 07/11/17.
//

protocol TagGroupProtocol {
    
    func getAll() throws -> [TagGroup]
    
    func get(id: Int) throws -> TagGroup?
    
    func getValues(id: Int) throws -> [TagValue]
    
    func add(item: TagGroup) throws
    
    func update(id: Int, item: TagGroup) throws
    
    func delete(id: Int) throws
}
