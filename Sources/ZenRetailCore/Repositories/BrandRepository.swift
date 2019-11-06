//
//  BrandRepository.swift
//  PerfectTurnstilePostgreSQLDemo
//
//  Created by Gerardo Grisolini on 16/02/17.
//
//

import NIO
import ZenPostgres

struct BrandRepository : BrandProtocol {

    func getAll() -> EventLoopFuture<[Brand]> {
        return Brand().queryAsync(orderby: ["brandId"])
    }
        
    func get(id: Int) -> EventLoopFuture<Brand> {
        let item = Brand()
        return item.getAsync(id).map { () -> Brand in
            return item
        }
    }
    
    func add(item: Brand) -> EventLoopFuture<Int> {
        if (item.brandSeo.permalink.isEmpty) {
            item.brandSeo.permalink = item.brandName.permalink()
        }
        item.brandSeo.description = item.brandSeo.description.filter({ !$0.value.isEmpty })
        item.brandDescription = item.brandDescription.filter({ !$0.value.isEmpty })
        item.brandCreated = Int.now()
        item.brandUpdated = Int.now()
        return item.saveAsync().map { id -> Int in
            id as! Int
        }
    }
    
    func update(id: Int, item: Brand) -> EventLoopFuture<Bool> {
        item.brandId = id
        if (item.brandSeo.permalink.isEmpty) {
            item.brandSeo.permalink = item.brandName.permalink()
        }
        item.brandUpdated = Int.now()
        return item.saveAsync().map { id -> Bool in
            id as! Int > 0
        }
    }
    
    func delete(id: Int) -> EventLoopFuture<Bool> {
        return Brand().deleteAsync(id)
    }
}
