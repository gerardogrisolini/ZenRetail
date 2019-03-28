//
//  CatgoryRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import ZenPostgres

struct CategoryRepository : CategoryProtocol {

    func getAll() throws -> [Category] {
        return try Category().query(orderby: ["categoryId"])
    }
    
    func get(id: Int) throws -> Category? {
        let item = Category()
		try item.get(id)
		
        return item
    }
    
    func add(item: Category) throws {
        if (item.categorySeo.permalink.isEmpty) {
            item.categorySeo.permalink = item.categoryName.permalink()
        }
        item.categorySeo.description = item.categorySeo.description.filter({ !$0.value.isEmpty })
        item.categoryDescription = item.categoryDescription.filter({ !$0.value.isEmpty })
        item.categoryCreated = Int.now()
        item.categoryUpdated = Int.now()
        try item.save {
            id in item.categoryId = id as! Int
        }
    }
    
    func update(id: Int, item: Category) throws {
        guard let current = try get(id: id) else {
            throw ZenError.noRecordFound
        }
        
        current.categoryIsPrimary = item.categoryIsPrimary
        current.categoryName = item.categoryName
        if (item.categorySeo.permalink.isEmpty) {
            item.categorySeo.permalink = item.categoryName.permalink()
        }
        current.categorySeo.description = item.categorySeo.description.filter({ !$0.value.isEmpty })
        current.categoryDescription = item.categoryDescription.filter({ !$0.value.isEmpty })
        current.categoryMedia = item.categoryMedia
        current.categorySeo = item.categorySeo
        current.categoryUpdated = Int.now()
        try current.save()
    }
    
    func delete(id: Int) throws {
        let item = Category()
        item.categoryId = id
        try item.delete()
    }
}
