//
//  StatisticProtocol.swift
//  ZenRetail
//
//  Created by Gerardo Grisolini on 20/06/17.
//

import NIO

protocol StatisticProtocol {
    
    func getDevices() -> EventLoopFuture<Statistics>
    
    func getCategories(year: Int) -> EventLoopFuture<Statistics>
    
    func getProducts(year: Int) -> EventLoopFuture<Statistics>
    
    func getCategoriesForMonth(year: Int) -> EventLoopFuture<Statistics>
    
    func getProductsForMonth(year: Int) -> EventLoopFuture<Statistics>
}

