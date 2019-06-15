//
//  BrandRepository.swift
//  PerfectTurnstilePostgreSQLDemo
//
//  Created by Gerardo Grisolini on 16/02/17.
//
//

import ZenPostgres

struct BrandRepository : BrandProtocol {

    func getAll() throws -> [Brand] {
        let items = Brand()
        return try items.query(orderby: ["brandId"])
    }
    
    func get(id: Int) throws -> Brand? {
        let item = Brand()
		try item.get(id)
		
        return item
    }
    
    func add(item: Brand) throws {
        if (item.brandSeo.permalink.isEmpty) {
            item.brandSeo.permalink = item.brandName.permalink()
        }
        item.brandSeo.description = item.brandSeo.description.filter({ !$0.value.isEmpty })
        item.brandDescription = item.brandDescription.filter({ !$0.value.isEmpty })
        item.brandCreated = Int.now()
        item.brandUpdated = Int.now()
        try item.save {
            id in item.brandId = id as! Int
        }
    }
    
    func update(id: Int, item: Brand) throws {
        guard let current = try get(id: id) else {
            throw ZenError.recordNotFound
        }
        
        current.brandName = item.brandName
        if (item.brandSeo.permalink.isEmpty) {
            item.brandSeo.permalink = item.brandName.permalink()
        }
        current.brandSeo.description = item.brandSeo.description.filter({ !$0.value.isEmpty })
        current.brandDescription = item.brandDescription.filter({ !$0.value.isEmpty })
        current.brandMedia = item.brandMedia
        current.brandSeo = item.brandSeo
        current.brandUpdated = Int.now()
        try current.save()
    }
    
    func delete(id: Int) throws {
        let item = Brand()
        item.brandId = id
        try item.delete()
    }
}
