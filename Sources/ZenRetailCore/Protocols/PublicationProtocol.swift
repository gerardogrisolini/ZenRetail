//
//  PublicationProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import NIO

protocol PublicationProtocol {
    
    func getAll() -> EventLoopFuture<[Publication]>
    
    func get(id: Int) -> EventLoopFuture<Publication>
    
    func getByProduct(productId: Int) -> EventLoopFuture<Publication>

    func add(item: Publication) -> EventLoopFuture<Int>
    
    func update(id: Int, item: Publication) -> EventLoopFuture<Bool>
    
    func delete(id: Int) -> EventLoopFuture<Bool>
}
