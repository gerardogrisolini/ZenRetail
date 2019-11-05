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
        return Brand().getAsync(id)
    }
    
    func add(item: Brand) -> EventLoopFuture<Int> {
        let promise: EventLoopPromise<Int> = ZenPostgres.pool.newPromise()

        if (item.brandSeo.permalink.isEmpty) {
            item.brandSeo.permalink = item.brandName.permalink()
        }
        item.brandSeo.description = item.brandSeo.description.filter({ !$0.value.isEmpty })
        item.brandDescription = item.brandDescription.filter({ !$0.value.isEmpty })
        item.brandCreated = Int.now()
        item.brandUpdated = Int.now()
        item.saveAsync().whenComplete { result in
            switch result {
            case .success(let id):
                promise.succeed(id as! Int)
            case .failure(let err):
                promise.fail(err)
            }
        }
        
        return promise.futureResult
    }
    
    func update(id: Int, item: Brand) -> EventLoopFuture<Bool> {
        let promise: EventLoopPromise<Bool> = ZenPostgres.pool.newPromise()

        item.brandId = id
        if (item.brandSeo.permalink.isEmpty) {
            item.brandSeo.permalink = item.brandName.permalink()
        }
        item.brandUpdated = Int.now()
        item.saveAsync().whenComplete { result in
            switch result {
            case .success(let id):
                promise.succeed(id as! Int > 0)
            case .failure(let err):
                promise.fail(err)
            }
        }

        return promise.futureResult
    }
    
    func delete(id: Int) -> EventLoopFuture<Bool> {
        return Brand().deleteAsync(id).map { count -> Bool in
            count > 0
        }
    }
}
