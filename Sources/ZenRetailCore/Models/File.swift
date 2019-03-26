//
//  File.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 13/05/18.
//

import Foundation
import NIOPostgres
import ZenPostgres


enum MediaSize {
    case small
    case big
}

class File: PostgresTable, Codable {
    
    public var fileId : Int = 0
    public var fileName : String = ""
    public var fileContentType : String = ""
    public var fileData : String = ""
    public var fileSize : Int = 0
    public var fileCreated : Int = Int.now()
    
    required init() {
        super.init()
    }
    
    override func decode(row: PostgresRow) {
        fileId = row.column("fileId")?.int ?? 0
        fileName = row.column("fileName")?.string ?? ""
        fileContentType = row.column("fileContentType")?.string ?? ""
        fileData = row.column("fileData")?.string ?? ""
        fileSize = row.column("fileSize")?.int ?? 0
        fileCreated = row.column("fileCreated")?.int ?? 0
    }
    
    func getData(filename: String, size: MediaSize) throws -> Data? {
        let order = size == .big ? "DESC" : "ASC"
        let files: [File] = try query(
            whereclause: "fileName = $1",
            params: [filename],
            orderby: ["fileSize \(order)"],
            cursor: Cursor(limit: 1, offset: 0)
        )
        if files.count > 0 {
            return Data(base64Encoded: files.first!.fileData, options: .ignoreUnknownCharacters)
        }
        return nil
    }

    func setData(data: Data) {
        self.fileSize = data.count
        self.fileData = data.base64EncodedString(options: .lineLength64Characters)
    }

    func setupShippingCost() throws {
        let fileNames = ["logo.png", "shippingcost.csv", "shippingcost_express.csv"]
        for fileName in fileNames {
            let files: [File] = try self.query(
                whereclause: "fileName = $1",
                params: [fileName],
                cursor: Cursor(limit: 1, offset: 0)
            )
            if files.count == 0 {
                if let data = FileManager.default.contents(atPath: "./webroot/media/\(fileName)") {
                    let file = File()
                    _ = try file.getData(filename: fileName, size: .big)
                    file.fileName = fileName
                    file.fileContentType = fileName.hasSuffix(".csv") ? "text/csv" : "image/png"
                    file.setData(data: data)
                    try file.save()
                }
            }
        }
    }
}
