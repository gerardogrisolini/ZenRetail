//
//  MwsRequest.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 22/04/18.
//

import Foundation
import NIOPostgres
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
    
    override func decode(row: PostgresRow) {
        id = row.column("id")?.int ?? 0
        requestSku = row.column("requestSku")?.string ?? ""
        requestXml = row.column("requestXml")?.string ?? ""
        request = row.column("request")?.int ?? 0
        requestParent = row.column("requestParent")?.int ?? 0
        
        requestSubmissionId = row.column("requestSubmissionId")?.string ?? ""
        requestCreatedAt = row.column("requestCreatedAt")?.int ?? 0
        requestSubmittedAt = row.column("requestSubmittedAt")?.int ?? 0
        requestCompletedAt = row.column("requestCompletedAt")?.int ?? 0
        
        messagesProcessed = row.column("messagesProcessed")?.int ?? 0
        messagesSuccessful = row.column("messagesSuccessful")?.int ?? 0
        messagesWithError = row.column("messagesWithError")?.int ?? 0
        messagesWithWarning = row.column("messagesWithWarning")?.int ?? 0
        errorDescription = row.column("errorDescription")?.string ?? ""
    }
    
    public func currentRequests() throws -> [MwsRequest] {
        return try self.query(orderby: ["requestCreatedAt DESC", "requestId"])
     }
    
    public func rangeRequests(startDate: Int, finishDate: Int) throws -> [MwsRequest] {
        return try self.query(
            whereclause: "requestCreatedAt >= $1 && requestCreatedAt <= $2 ",
            params: [startDate, finishDate],
            orderby: ["requestCreatedAt DESC", "requestId"]
        )
    }

    public func lastRequest() throws -> Int {
        let sql = "SELECT MAX(\"requestCreatedAt\") AS counter FROM \"\(table)\""
        let getCount = try self.sqlRows(sql)
        return getCount.first?.column("counter")?.int ?? 0
    }
}
