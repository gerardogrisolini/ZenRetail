//
//  File.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 13/05/18.
//

import Foundation
import PostgresClientKit
import ZenPostgres
import ZenNIO

enum MediaType: String {
    case thumb
    case media
    case csv
}

//class File {
//    let fileManager = FileManager.default
//    public var fileId : Int = 0
//    public var fileName : String = ""
//    public var fileContentType : String = ""
//    public var fileType : MediaType = .media
//    public var fileData : Data? = nil
//    public var fileSize : Int = 0
//    public var fileCreated : Int = Int.now()
//
//    func setupShippingCost() throws {
//        if !FileManager.default.fileExists(atPath: "\(ZenNIO.htdocsPath)/media/logo.png") {
//            let fileNames = ["logo.png", "shippingcost.csv", "shippingcost_express.csv"]
//            for fileName in fileNames {
//                if let data = FileManager.default.contents(atPath: "./Assets/\(fileName)") {
//                    let file = File()
//                    file.fileName = fileName
//                    file.fileContentType = fileName.hasSuffix(".csv") ? "text/csv" : "image/png"
//                    file.setData(data: data)
//                    try file.save()
//                }
//            }
//        }
//    }
//
//    func setData(data: Data) {
//        self.fileSize = data.count
//        self.fileData = data
//    }
//
//    func create() throws {
//        let paths = ["csv", "media", "thumb"]
//        for path in paths {
//            var isDirectory: ObjCBool = true
//            let p = "\(ZenNIO.htdocsPath)/\(path)"
//            if !fileManager.fileExists(atPath: p, isDirectory: &isDirectory) {
//                try fileManager.createDirectory(atPath: p, withIntermediateDirectories: true, attributes: nil)
//            }
//        }
//    }
//
//    func save() throws {
//        var path = "media"
//        if fileContentType == "text/csv" {
//            path = "csv"
//        } else if fileType == .thumb {
//            path = "thumb"
//        }
//        if !fileManager.createFile(atPath: "\(ZenNIO.htdocsPath)/\(path)/\(fileName)", contents: fileData, attributes: nil) {
//            throw ZenError.error("file not saved")
//        }
//    }
//}

class File: PostgresTable, Codable {

    public var fileId : Int = 0
    public var fileName : String = ""
    public var fileContentType : String = ""
    public var fileType : String = "media"
    public var fileData : Data = Data()
    public var fileSize : Int = 0
    public var fileCreated : Int = Int.now()

    override func decode(row: Row) {
        fileId = (try? row.columns[0].int()) ?? fileId
        fileName = (try? row.columns[1].string()) ?? fileName
        fileContentType = (try? row.columns[2].string()) ?? fileContentType
        fileType = (try? row.columns[3].string()) ?? fileType
        fileData = (try? row.columns[4].byteA().data) ?? fileData
        fileSize = (try? row.columns[5].int()) ?? fileSize
        fileCreated = (try? row.columns[6].int()) ?? fileCreated
    }

    func getData(filename: String, size: MediaType) throws -> Data? {
//        var name = filename
//        if let index = name.firstIndex(of: "?") {
//            name = name[name.startIndex...name.index(before: index)].description
//        }

        let files: [File] = try query(
            whereclause: "fileName = $1 AND fileType = $2",
            params: [filename, size.rawValue],
            cursor: CursorConfig(limit: 1, offset: 0)
        )
        if files.count > 0 {
            return files.first!.fileData
        }
        return nil
    }
    
    func setData(data: Data) {
        fileData = data
        fileSize = data.count
    }

    func setupShippingCost() throws {
        let fileNames = ["logo.png", "shippingcost.csv", "shippingcost_express.csv"]
        for fileName in fileNames {
            let files: [File] = try self.query(
                whereclause: "fileName = $1",
                params: [fileName],
                cursor: CursorConfig(limit: 1, offset: 0)
            )
            if files.count == 0 {
                if let data = FileManager.default.contents(atPath: "./Assets/\(fileName)") {
                    let file = File(db: db!)
                    file.fileName = fileName
                    file.fileContentType = fileName.hasSuffix(".csv") ? "text/csv" : "image/png"
                    file.fileType = fileName.hasSuffix(".csv") ? MediaType.csv.rawValue : MediaType.media.rawValue
                    file.setData(data: data)
                    try file.save()
                }
            }
        }
    }

//    func importStaticFiles() throws {
//        let types = ["media", "thumb"]
//            for type in types {
//            let fileNames = try FileManager.default.contentsOfDirectory(atPath: "./webroot/\(type)")
//            for fileName in fileNames {
//                let files: [File] = try self.query(
//                    whereclause: "fileName = $1 AND fileType = $2",
//                    params: [fileName, type],
//                    cursor: CursorConfig(limit: 1, offset: 0)
//                )
//                if files.count == 0 {
//                    if let data = FileManager.default.contents(atPath: "./webroot/\(type)/\(fileName)") {
//                        let file = File(db: db!)
//                        file.fileName = fileName
//                        file.fileContentType = fileName.hasSuffix(".csv") ? "text/csv" : "image/png"
//                        file.fileType = type
//                        file.setData(data: data)
//                        try file.save()
//                    }
//                }
//            }
//        }
//    }
    
    override func save() throws {
        let text = """
INSERT INTO "File" ("fileName", "fileContentType", "fileType", "fileData", "fileSize", "fileCreated")
VALUES ($1, $2, $3, $4, $5, $6)
"""
        let statement = try db!.prepareStatement(text: text)
        defer { statement.close() }
        let cursor = try statement.execute(parameterValues: [
            fileName,
            fileContentType,
            fileType,
            PostgresByteA(data: fileData),
            fileSize,
            fileCreated
        ])
        cursor.close()
    }
}

