//
//  StatisticController.swift
//  macWebretail
//
//  Created by Gerardo Grisolini on 20/06/17.
//  Copyright © 2017 Gerardo Grisolini. All rights reserved.
//

import ZenNIO

class StatisticController {
    
    private let repository: StatisticProtocol
    
    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as StatisticProtocol

        router.get("/api/statistic/device", handler: statisticDeviceHandlerGET)
        router.get("/api/statistic/category/:year", handler: statisticCategoryHandlerGET)
        router.get("/api/statistic/categoryformonth/:year", handler: statisticCategoryformonthHandlerGET)
        router.get("/api/statistic/product/:year", handler: statisticProductHandlerGET)
        router.get("/api/statistic/productformonth/:year", handler: statisticProductformonthHandlerGET)
    }

    func statisticDeviceHandlerGET(request: HttpRequest, response: HttpResponse) {
        self.repository.getDevices().whenComplete { result in
            do {
                switch result {
                case .success(let items):
                    try response.send(json: items)
                    response.success()
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func statisticCategoryHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let year: Int = request.getParam("year") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter year")
            return
        }
        
        self.repository.getCategories(year: year).whenComplete { result in
            do {
                switch result {
                case .success(let item):
                    try response.send(json: item)
                    response.success()
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func statisticCategoryformonthHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let year: Int = request.getParam("year") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter year")
            return
        }
        
        self.repository.getCategoriesForMonth(year: year).whenComplete { result in
            do {
                switch result {
                case .success(let item):
                    try response.send(json: item)
                    response.success()
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func statisticProductHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let year: Int = request.getParam("year") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter year")
            return
        }
        
        self.repository.getProducts(year: year).whenComplete { result in
            do {
                switch result {
                case .success(let item):
                    try response.send(json: item)
                    response.success()
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func statisticProductformonthHandlerGET(request: HttpRequest, response: HttpResponse) {
        guard let year: Int = request.getParam("year") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter year")
            return
        }
        
        self.repository.getProductsForMonth(year: year).whenComplete { result in
            do {
                switch result {
                case .success(let item):
                    try response.send(json: item)
                    response.success()
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }
}
