//
//  File.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 13/05/18.
//

import Foundation
import PostgresNIO
import ZenPostgres
import ZenNIO

enum MediaType: String {
    case thumb
    case media
    case csv
}

class File: PostgresTable, Codable {

    public var fileId : Int = 0
    public var fileName : String = ""
    public var fileContentType : String = ""
    public var fileType : String = "media"
    public var fileData : [UInt8] = [UInt8]()
    public var fileSize : Int = 0
    public var fileCreated : Int = Int.now()

    override func decode(row: PostgresRow) {
        fileId = row.column("fileId")?.int ?? 0
        fileName = row.column("fileName")?.string ?? ""
        fileContentType = row.column("fileContentType")?.string ?? ""
        fileType = row.column("fileType")?.string ?? fileType
        fileData = row.column("fileData")?.bytes ?? fileData
        fileSize = row.column("fileSize")?.int ?? 0
        fileCreated = row.column("fileCreated")?.int ?? 0
    }

    func setData(data: Data) {
        fileData = [UInt8](data)
        fileSize = data.count
    }
    
    override func saveAsync() -> EventLoopFuture<Any> {
        let sql = """
INSERT INTO "File" ("fileName", "fileContentType", "fileType", "fileData", "fileSize", "fileCreated")
VALUES ($1, $2, $3, $4, $5, $6)
"""
        let postgresData = [
            PostgresData(string: fileName),
            PostgresData(string: fileContentType),
            PostgresData(string: fileType),
            PostgresData(bytes: fileData),
            PostgresData(int: fileSize),
            PostgresData(int: fileCreated)
        ]

        func saveFile() -> EventLoopFuture<Any> {
            return connection!.query(sql, postgresData).flatMapThrowing { rows -> Any in
                if let id = rows.first?.column("fileId")?.int {
                    return id
                }
                throw ZenError.recordNotSave
            }
        }
        
        if connection == nil {
            return ZenPostgres.pool.connectAsync().flatMap { conn -> EventLoopFuture<Any> in
                self.connection = conn
                defer { conn.disconnect() }
                return saveFile()
            }
        }

        return saveFile()
    }
    
    func getDataAsync(filename: String, size: MediaType) -> EventLoopFuture<[UInt8]> {
        let query: EventLoopFuture<[File]> = queryAsync(
            whereclause: "fileName = $1 AND fileType = $2",
            params: [filename, size.rawValue],
            cursor: Cursor(limit: 1, offset: 0)
        )
        
        return query.flatMapThrowing { files -> [UInt8] in
            if let file = files.first {
                return file.fileData
            } else {
                throw ZenError.recordNotFound
            }
        }
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
                if let data = FileManager.default.contents(atPath: "./Assets/\(fileName)") {
                    let file = File(connection: connection!)
                    file.fileName = fileName
                    file.fileContentType = fileName.hasSuffix(".csv") ? "text/csv" : "image/png"
                    file.fileType = fileName.hasSuffix(".csv") ? MediaType.csv.rawValue : MediaType.media.rawValue
                    file.setData(data: data)
                    try file.save()
                }
            }
        }
    }

    /*
    func importStaticFiles() throws {
        let types = ["media", "thumb"]
            for type in types {
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: "./webroot/\(type)")
            for fileName in fileNames {
                let files: [File] = try self.query(
                    whereclause: "fileName = $1 AND fileType = $2",
                    params: [fileName, type],
                    cursor: Cursor(limit: 1, offset: 0)
                )
                if files.count == 0 {
                    if let data = FileManager.default.contents(atPath: "./webroot/\(type)/\(fileName)") {
                        let file = File(connection: connection!)
                        file.fileName = fileName
                        file.fileContentType = fileName.hasSuffix(".csv") ? "text/csv" : "image/png"
                        file.fileType = type
                        file.setData(data: data)
                        try file.save()
                    }
                }
            }
        }
    }
    
    override func save() throws {
        let sql = """
INSERT INTO "File" ("fileName", "fileContentType", "fileType", "fileData", "fileSize", "fileCreated")
VALUES ($1, $2, $3, $4, $5, $6)
"""
        let postgresData = [
            PostgresData(string: fileName),
            PostgresData(string: fileContentType),
            PostgresData(string: fileType),
            PostgresData(bytes: fileData),
            PostgresData(int: fileSize),
            PostgresData(int: fileCreated)
        ]
        
        guard let connection = connection else {
            throw ZenError.connectionNotFound
        }
        
        var error: Error?
        let semaphore = DispatchSemaphore(value: 0)
        let query = connection.query(sql, postgresData)
        
        query.whenComplete { result in
            switch result {
            case .success(_):
                error = nil
            case .failure(let err):
                error = err
            }
            semaphore.signal()
        }

        semaphore.wait()
        
        if let error = error {
            throw error
        }
    }
    
    func getData(filename: String, size: MediaType) throws -> [UInt8]? {
//        var name = filename
//        if let index = name.firstIndex(of: "?") {
//            name = name[name.startIndex...name.index(before: index)].description
//        }

        let files: [File] = try query(
            whereclause: "fileName = $1 AND fileType = $2",
            params: [filename, size.rawValue],
            cursor: Cursor(limit: 1, offset: 0)
        )
        if files.count > 0 {
            return files[0].fileData
        }
        return nil
    }
    */
}

