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
        request.eventLoop.execute {
            do {
                let items = try self.repository.getDevices()
                try response.send(json:items)
                response.completed()
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func statisticCategoryHandlerGET(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            do {
                guard let year: Int = request.getParam("year") else {
                    throw HttpError.badRequest
                }
                let items = try self.repository.getCategories(year: year)
                try response.send(json:items)
                response.completed()
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func statisticCategoryformonthHandlerGET(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            do {
                guard let year: Int = request.getParam("year") else {
                    throw HttpError.badRequest
                }
                let items = try self.repository.getCategoriesForMonth(year: year)
                try response.send(json:items)
                response.completed()
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func statisticProductHandlerGET(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            do {
                guard let year: Int = request.getParam("year") else {
                    throw HttpError.badRequest
                }
                let items = try self.repository.getProducts(year: year)
                try response.send(json:items)
                response.completed()
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func statisticProductformonthHandlerGET(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            do {
                guard let year: Int = request.getParam("year") else {
                    throw HttpError.badRequest
                }
                let items = try self.repository.getProductsForMonth(year: year)
                try response.send(json:items)
                response.completed()
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }
}
