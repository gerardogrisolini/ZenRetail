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
    public var fileType : String = ""
    public var fileData : String = ""
    public var fileSize : Int = 0
    public var fileCreated : Int = Int.now()
    
    required init() {
        super.init()
    }
    
    override func decode(row: Row) {
        fileId = (try? row.columns[0].int()) ?? 0
        fileName = (try? row.columns[1].string()) ?? ""
        fileContentType = (try? row.columns[2].string()) ?? ""
        fileType = (try? row.columns[3].string()) ?? "media"
        fileData = (try? row.columns[4].string()) ?? ""
        fileSize = (try? row.columns[5].int()) ?? 0
        fileCreated = (try? row.columns[6].int()) ?? 0
    }
    
    func getData(filename: String, size: MediaType) throws -> Data? {
        var name = filename
        if let index = name.firstIndex(of: "?") {
            name = name[name.startIndex...name.index(before: index)].description
        }

        let files: [File] = try query(
            whereclause: "fileName = $1 AND fileType = $2",
            params: [name, size.rawValue],
            cursor: CursorConfig(limit: 1, offset: 0)
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
                cursor: CursorConfig(limit: 1, offset: 0)
            )
            if files.count == 0 {
                if let data = FileManager.default.contents(atPath: "./Assets/\(fileName)") {
                    let file = File()
                    //_ = try file.getData(filename: fileName, size: fileName.hasSuffix(".csv") ? .csv : .media)
                    file.fileName = fileName
                    file.fileContentType = fileName.hasSuffix(".csv") ? "text/csv" : "image/png"
                    file.fileType = fileName.hasSuffix(".csv") ? MediaType.csv.rawValue : MediaType.media.rawValue
                    file.setData(data: data)
                    try file.save()
                }
            }
        }
    }
}

