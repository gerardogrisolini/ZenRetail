//
//  AmazonControler.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 22/04/18.
//

import Foundation
import NIO
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
        
        loadConfig().whenSuccess { _ in }
        
        router.get("/api/mws/config", handler: mwsConfigHandlerGET)
        router.put("/api/mws/config", handler: mwsConfigHandlerPUT)
        router.get("/api/mws", handler: mwsHandlerGET)
        router.get("/api/mws/:start/:finish", handler: mwsHandlerGET)
    }
    
    func mwsConfigHandlerGET(request: HttpRequest, response: HttpResponse) {
        do {
            try response.send(json: config)
            response.completed()
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func mwsConfigHandlerPUT(request: HttpRequest, response: HttpResponse) {
        guard let data = request.bodyData,
            let amazon = try? JSONDecoder().decode(Amazon.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }
        self.config = Config(
            endpoint: amazon.endpoint,
            marketplaceId: amazon.marketplaceId,
            sellerId: amazon.sellerId,
            accessKey: amazon.accessKey,
            secretKey: amazon.secretKey,
            authToken: amazon.authToken,
            userAgent: amazon.userAgent
        )
        
        ZenPostgres.pool.connect().whenComplete { result in
            switch result {
            case .success(let conn):
                amazon.save(connection: conn).whenComplete { res in
                    switch res {
                    case .success(_):
                        try? response.send(json: self.config)
                        response.completed()
                    case .failure(let err):
                        response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
                    }
                }
            case .failure(let err):
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
            }
        }
    }

    func mwsHandlerGET(request: HttpRequest, response: HttpResponse) {
        var mwsRequest: EventLoopFuture<[MwsRequest]>
        if let start: Int = request.getParam("start"), let finish: Int = request.getParam("finish") {
            mwsRequest = MwsRequest().rangeRequests(startDate: start, finishDate: finish)
        } else {
            mwsRequest = MwsRequest().currentRequests()
        }

        mwsRequest.whenComplete { result in
            do {
                switch result {
                case .success(let data):
                    try response.send(json: data)
                    response.completed()
                case .failure(let err):
                    throw err
                }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }
    
    // Background worker
    
    fileprivate func loadConfig() -> EventLoopFuture<Void> {
        let amazon = Amazon()
        return amazon.select().map { () -> Void in
            self.config = Config(
                endpoint: amazon.endpoint,
                marketplaceId: amazon.marketplaceId,
                sellerId: amazon.sellerId,
                accessKey: amazon.accessKey,
                secretKey: amazon.secretKey,
                authToken: amazon.authToken,
                userAgent: amazon.userAgent
            )
            
            //TODO: decomment
//            if !amazon.authToken.isEmpty {
//                self.startWorker()
//            }
        }
     }
    
    fileprivate func startWorker() {
        DispatchQueue.global(qos: .utility).async {
            while(true) {
                
                if self.mws.isSubmitted() {
                    var requests = [RequestFeed]()
                    
                    self.repository.getAmazonChanges().whenSuccess { products in
                        products.forEach { p in
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
                        }
                        
                        self.mws.start(requests: requests)
                    }
                
                    sleep(180)
                }
            }
        }
    }

    func callBack(request: RequestFeed) {
        do {
            let mwsRequest = MwsRequest()
            try mwsRequest.get("requestId", request.requestId).wait()
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
            mwsRequest.id = try mwsRequest.save().wait() as! Int
            if mwsRequest.requestCompletedAt > 0 {
                _ = try Product().update(cols: ["productAmazonUpdated"], params: [Int.now()], id: "productCode", value: mwsRequest.requestSku).wait()
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

