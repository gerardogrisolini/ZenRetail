//
//  AmazonControler.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 22/04/18.
//

import Foundation
import ZenNIO
import ZenMWS
import ZenPostgres

public class AmazonController: NSObject {
    
    private let repository: ProductProtocol
    private var config: Config!

    lazy var mws = ZenMWS(config: config, notify: callBack)

    init(router: Router) {
        self.repository = ZenIoC.shared.resolve() as ProductProtocol
        super.init()
        
        loadConfig()
        
        router.get("/api/mws/config", handler: mwsConfigHandlerGET)
        router.put("/api/mws/config", handler: mwsConfigHandlerPUT)
        router.get("/api/mws", handler: mwsHandlerGET)
        router.get("/api/mws/:start/:finish", handler: mwsHandlerGET)
    }
    
    func mwsConfigHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            try response.send(json:config)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func mwsConfigHandlerPUT(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            do {
                guard let data = request.bodyData else {
                    throw HttpError.badRequest
                }
                let amazon = try JSONDecoder().decode(Amazon.self, from: data)
                try amazon.save()
                
                self.config = Config(
                    endpoint: amazon.endpoint,
                    marketplaceId: amazon.marketplaceId,
                    sellerId: amazon.sellerId,
                    accessKey: amazon.accessKey,
                    secretKey: amazon.secretKey,
                    authToken: amazon.authToken,
                    userAgent: amazon.userAgent
                )
                
                try response.send(json: self.config)
                response.completed()
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func mwsHandlerGET(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            let data: [MwsRequest]
            do {
                let mwsRequest = MwsRequest()
                if let start: Int = request.getParam("start"),
                    let finish: Int = request.getParam("finish") {
                    data = try mwsRequest.rangeRequests(startDate: start, finishDate: finish)
                } else {
                    data = try mwsRequest.currentRequests()
                }
                
                try response.send(json:data)
                response.completed()
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }
    
    // Background worker
    
    fileprivate func loadConfig() {
        let amazon = Amazon()
        try? amazon.select()
        config = Config(
            endpoint: amazon.endpoint,
            marketplaceId: amazon.marketplaceId,
            sellerId: amazon.sellerId,
            accessKey: amazon.accessKey,
            secretKey: amazon.secretKey,
            authToken: amazon.authToken,
            userAgent: amazon.userAgent
        )
        
        //TODO: decomment
//        if !amazon.authToken.isEmpty {
//            self.startWorker()
//        }
    }
    
    fileprivate func startWorker() {
        DispatchQueue.global(qos: .background).async {
            while(true) {
                
                if self.mws.isSubmitted() {
                    do {
                        var requests = [RequestFeed]()
                        
                        let products = try self.repository.getAmazonChanges()
                        products.forEach({ (p) in
                            var index = Int.now()
                            if p.productAmazonUpdated == 1 {
                                let parent = index
                                requests.append(RequestFeed(sku: p.productCode, feed : p.productFeed(), id: index, parentId: 0))
                                //if p.productType == "Variant" {
                                if p._articles.count > 1 {
                                    index += 1
                                    requests.append(RequestFeed(sku: p.productCode, feed : p.relationshipFeed(), id: index, parentId: parent))
                                }
                                index += 1
                                requests.append(RequestFeed(sku: p.productCode, feed : p.priceFeed(), id: index, parentId: parent))
                                index += 1
                                requests.append(RequestFeed(sku: p.productCode, feed : p.inventoryFeed()!, id: index, parentId: parent))
                                index += 1
                                requests.append(RequestFeed(sku: p.productCode, feed : p.imageFeed(), id: index, parentId: parent))
                            } else if let feed = p.inventoryFeed() {
                                requests.append(RequestFeed(sku: p.productCode, feed : feed, id: index, parentId: 0))
                            }
                        })
                        
                        self.mws.start(requests: requests)
                    } catch {
                        print("mwsRequest: \(error)")
                    }
                }
                
                sleep(180)
            }
        }
    }

    func callBack(request: RequestFeed) {
        do {
            let mwsRequest = MwsRequest()
            try mwsRequest.get("requestId", request.requestId)
            mwsRequest.request = request.requestId
            mwsRequest.requestParent = request.requestParentId
            mwsRequest.requestSubmissionId = request.requestSubmissionId
            mwsRequest.requestSku = request.requestSku
            mwsRequest.requestXml = request.requestFeed.xml(compact: false)
            mwsRequest.requestCreatedAt = request.requestCreatedAt
            mwsRequest.requestSubmittedAt = request.requestSubmittedAt
            mwsRequest.requestCompletedAt = request.requestCompletedAt
            mwsRequest.messagesProcessed = request.messagesProcessed
            mwsRequest.messagesSuccessful = request.messagesSuccessful
            mwsRequest.messagesWithError = request.messagesWithError
            mwsRequest.messagesWithWarning = request.messagesWithWarning
            mwsRequest.errorDescription = request.errorDescription
            try mwsRequest.save()
            if mwsRequest.requestCompletedAt > 0 {
                _ = try Product().update(cols: ["productAmazonUpdated"], params: [Int.now()], id: "productCode", value: mwsRequest.requestSku)
            }
        } catch {
            print("callBack: \(error)")
        }

//        print("\(request.requestSubmissionId): \(request.requestSubmittedAt) => \(request.requestCompletedAt)")
//        if request.requestCompletedAt == 0 {
//            print(request.requestFeed.xml())
//        }
    }
}

