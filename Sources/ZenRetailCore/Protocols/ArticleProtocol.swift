//
//  ArticleProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import NIO
import PostgresNIO

protocol ArticleProtocol {
    
    func build(productId: Int) -> EventLoopFuture<Result>

    func get(productId: Int, storeIds: String) -> EventLoopFuture<[Article]>
    
    func get(id: Int) -> EventLoopFuture<Article>
    
	func getStock(productId: Int, storeIds: String, tagId: Int) -> EventLoopFuture<ArticleForm>

    func getGrouped(productId: Int) -> EventLoopFuture<[GroupItem]>

    func add(item: Article) -> EventLoopFuture<Int>
    
    func addGroup(item: Article) -> EventLoopFuture<GroupItem>
    
    func update(id: Int, item: Article) -> EventLoopFuture<Bool>
    
    func delete(id: Int) -> EventLoopFuture<Bool>

    func addAttributeValue(item: ArticleAttributeValue) -> EventLoopFuture<Int>
    
    func removeAttributeValue(id: Int) -> EventLoopFuture<Bool>
}


struct ArticleForm: Codable {
	public var header: [String]
	public var body: [[ArticleItem]]
}

struct ArticleItem: Codable {
	public var id: Int
	public var value: String
	public var stock: Double
	public var booked: Double
	public var data: Double
}

struct GroupItem: Codable {
    public var id: Int
    public var barcode: String
    public var product: Product
}
