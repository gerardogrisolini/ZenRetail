//
//  StatisticProtocol.swift
//  macWebretail
//
//  Created by Gerardo Grisolini on 20/06/17.
//

protocol StatisticProtocol {
    
    func getDevices() throws -> Statistics
    
    func getCategories(year: Int) throws -> Statistics
    
    func getProducts(year: Int) throws -> Statistics
    
    func getCategoriesForMonth(year: Int) throws -> Statistics
    
    func getProductsForMonth(year: Int) throws -> Statistics
}

