//
//  MovementArticleProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 01/03/17.
//
//

protocol MovementArticleProtocol {
    
    func get(movementId: Int) throws -> [MovementArticle]
    
    func get(id: Int) throws -> MovementArticle?
    
    func add(item: MovementArticle, price: String) throws
    
    func update(id: Int, item: MovementArticle) throws
    
    func delete(id: Int) throws

	func clone(sourceMovementId: Int, targetMovementId: Int, price: String) throws
}
