//
//  ArticleProtocol.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

protocol ArticleProtocol {
    
    func build(productId: Int) throws -> Result

    func get(productId: Int, storeIds: String) throws -> [Article]
    
    func get(id: Int) throws -> Article?
    
	func getStock(productId: Int, storeIds: String, tagId: Int) throws -> ArticleForm

    func getGrouped(productId: Int) throws -> [GroupItem]

    func add(item: Article) throws
    
    func addGroup(item: Article) throws -> GroupItem
    
    func update(id: Int, item: Article) throws
    
    func delete(id: Int) throws

    func addAttributeValue(item: ArticleAttributeValue) throws
    
    func removeAttributeValue(id: Int) throws
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
