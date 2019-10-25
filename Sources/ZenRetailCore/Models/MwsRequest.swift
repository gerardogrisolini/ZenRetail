//
//  MwsRequest.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 22/04/18.
//

import Foundation
import PostgresClientKit
import ZenPostgres


class MwsRequest : PostgresTable, Codable {
    
    public var id: Int = 0
    public var requestSku : String = ""
    public var requestXml : String = ""
    public var request: Int = 0
    public var requestParent: Int = 0
    
    public var requestSubmissionId: String = ""
    public var requestCreatedAt: Int = Int.now()
    public var requestSubmittedAt: Int = 0
    public var requestCompletedAt: Int = 0
    
    public var messagesProcessed: Int = 0
    public var messagesSuccessful: Int = 0
    public var messagesWithError: Int = 0
    public var messagesWithWarning: Int = 0
    public var errorDescription: String = ""
    
    required init() {
        super.init()
    }
    
    override func decode(row: Row) {
        id = (try? row.columns[0].int()) ?? 0
        requestSku = (try? row.columns[1].string()) ?? ""
        requestXml = (try? row.columns[2].string()) ?? ""
        request = (try? row.columns[3].int()) ?? 0
        requestParent = (try? row.columns[4].int()) ?? 0
        
        requestSubmissionId = (try? row.columns[5].string()) ?? ""
        requestCreatedAt = (try? row.columns[6].int()) ?? 0
        requestSubmittedAt = (try? row.columns[7].int()) ?? 0
        requestCompletedAt = (try? row.columns[8].int()) ?? 0
        
        messagesProcessed = (try? row.columns[9].int()) ?? 0
        messagesSuccessful = (try? row.columns[10].int()) ?? 0
        messagesWithError = (try? row.columns[11].int()) ?? 0
        messagesWithWarning = (try? row.columns[12].int()) ?? 0
        errorDescription = (try? row.columns[13].string()) ?? ""
    }
    
    public func currentRequests() throws -> [MwsRequest] {
        return try self.query(orderby: ["requestCreatedAt DESC", "request"])
     }
    
    public func rangeRequests(startDate: Int, finishDate: Int) throws -> [MwsRequest] {
        return try self.query(
            whereclause: "requestCreatedAt >= $1 && requestCreatedAt <= $2 ",
            params: [startDate, finishDate],
            orderby: ["requestCreatedAt DESC", "requestId"]
        )
    }

    public func lastRequest() throws -> Int {
        let sql = "SELECT COALESCE(MAX(\"requestCreatedAt\"),0) AS counter FROM \"\(table)\""
        let getCount = try self.sqlRows(sql)
        return (try? getCount.first?.columns[0].int()) ?? 0
    }
}
