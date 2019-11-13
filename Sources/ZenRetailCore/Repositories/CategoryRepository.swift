//
//  CatgoryRepository.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 17/02/17.
//
//

import NIO
import ZenPostgres

struct CategoryRepository : CategoryProtocol {

    func getAll() -> EventLoopFuture<[Category]> {
        return Category().queryAsync(orderby: ["categoryId"])
    }
    
    func get(id: Int) -> EventLoopFuture<Category> {
        let item = Category()
		return item.getAsync(id).map { () -> Category in
            return item
        }
    }
    
    func add(item: Category) -> EventLoopFuture<Int> {
        if item.categoryIsPrimary {
            if (item.categorySeo == nil) {
                item.categorySeo = Seo()
                item.categorySeo!.permalink = item.categoryName.permalink()
            }
            item.categorySeo!.description = item.categorySeo!.description.filter({ !$0.value.isEmpty })
        }
        
        item.categoryDescription = item.categoryDescription.filter({ !$0.value.isEmpty })
        item.categoryCreated = Int.now()
        item.categoryUpdated = Int.now()
        return item.saveAsync().map { id -> Int in
            item.categoryId = id as! Int
            return item.categoryId
        }
    }
    
    func update(id: Int, item: Category) -> EventLoopFuture<Bool> {
        item.categoryId = id
        if item.categoryIsPrimary {
            if (item.categorySeo != nil) {
                item.categorySeo = Seo()
                item.categorySeo!.permalink = item.categoryName.permalink()
            }
        }
        item.categoryUpdated = Int.now()
        return item.saveAsync().map { count -> Bool in
            count as! Int > 0
        }
    }
    
    func delete(id: Int) -> EventLoopFuture<Bool> {
        return Category().deleteAsync(id)
    }
}
