//
//  CompanyController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 11/04/17.
//
//

import Foundation
import NIO
import ZenNIO
import ZenPostgres
import ZenSMTP
import SwiftImage


class CompanyController {
	
    init(router: Router) {
        router.get("/api/company", handler: companyHandlerGET)
		router.post("/api/company", handler: companyHandlerPOST)
		router.post("/api/media", handler: uploadMediaHandlerPOST)
        router.post("/api/medias", handler: uploadMediasHandlerPOST)
        router.post("/api/email", handler: emailHandlerPOST)
        
//        router.get("/media/:filename", handler: {
//            request, response in
//            self.getFile(request, response, .media)
//        })
//        router.get("/thumb/:filename", handler: {
//            request, response in
//            self.getFile(request, response, .thumb)
//        })
        router.get("/csv/:filename", handler: {
            request, response in
            self.getFile(request, response, .csv)
        })
    }
    
    
    fileprivate func getFile(_ request: HttpRequest, _ response: HttpResponse, _ size: MediaType) {
        if let filename: String = request.getParam("filename") {
            File().getFileAsync(filename: filename, size: size).whenComplete { result in
                switch result {
                case .success(let file):
                    response.addHeader(.contentType, value: file.fileContentType)
                    response.body.reserveCapacity(file.fileData.count)
                    response.body.writeBytes(file.fileData)
                    response.success()
                case .failure(_):
                    response.success(.notFound)
                }
            }
        } else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter filename")
        }
    }

    fileprivate func saveFiles(_ fileName: String, _ data: Data) -> EventLoopFuture<Media> {
        let media = Media()
        media.contentType = fileName.contentType
        media.name = fileName != "logo.png" && fileName != "header.png" ? fileName.uniqueName() : fileName

        return ZenPostgres.pool.connect().flatMap { connection -> EventLoopFuture<Media> in
            defer { connection.disconnect() }

            let big = File(connection: connection)
            big.fileName = media.name
            big.fileType = fileName.hasSuffix(".csv") ? MediaType.csv.rawValue : MediaType.media.rawValue
            big.fileContentType = media.contentType
            big.setData(data: data)
            return big.save().flatMap { id -> EventLoopFuture<Media> in
                if fileName.contentType.hasPrefix("image/"),
                    let thumb = Image<RGBA<UInt8>>(data: data),
                    let export = thumb.resizedTo(width: 380, height: 380).data(using: .png) {
                    let small = File(connection: connection)
                    small.fileName = media.name
                    small.fileType = MediaType.thumb.rawValue
                    small.fileContentType = media.contentType
                    small.setData(data: export)
                    return big.save().map { id -> Media in
                        return media
                    }
                }
                return connection.eventLoop.future(media)
            }
        }
    }

    func companyHandlerGET(request: HttpRequest, response: HttpResponse) {
        let item = Company()
        item.select().whenComplete { result in
            do {
                switch result {
                case .success(_):
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

    func companyHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let data = request.bodyData,
            let item = try? JSONDecoder().decode(Company.self, from: data) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }
        
        item.save().whenComplete { result in
            do {
                switch result {
                case .success(_):
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
    
    func uploadMediaHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let fileName: String = request.getParam("file[]"),
            let file: Data = request.getParam(fileName) else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter file[]")
            return
        }

        self.saveFiles(fileName, file).whenComplete { result in
            do {
            switch result {
            case .success(let media):
                print("Uploaded file \(fileName) => \(media.name)")
                try response.send(json: media)
                response.success( .created)
            case .failure(let err):
                throw err
            }
            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }

    func uploadMediasHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let fileNames: String = request.getParam("file[]") else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): parameter file[]")
            return
        }

        var medias = [Media]()
        let files = fileNames.split(separator: ",")
        for fileName in files {
            if let file: Data = request.getParam(fileName.description) {
                self.saveFiles(fileName.description, file).whenComplete { result in
                    switch result {
                    case .success(let media):
                        medias.append(media)
                        print("Uploaded file \(fileName) => \(media.name)")
                    case .failure(let err):
                        print("Uploaded file \(fileName): \(err)")
                        medias.append(Media())
                    }
                    
                    if medias.count == files.count {
                        try? response.send(json: medias)
                        response.success(.created)
                    }
                }
            }
        }
    }

    func emailHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let data = request.bodyData else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
            return
        }
        
        guard let item = try? JSONDecoder().decode(PdfDocument.self, from: data), !item.address.isEmpty else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): email address to is empty")
            return
        }
        
        let company = Company()
        company.select().whenComplete { result in
            if company.companyEmailInfo.isEmpty {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): email address from is empty")
                return
            }
            
            let email = Email(
                fromName: company.companyName,
                fromEmail: company.companyEmailSupport,
                toName: nil,
                toEmail: item.address,
                subject: item.subject,
                body: item.content,
                attachments: []
            )
            
            ZenSMTP.mail.send(email: email).whenComplete { result in
                switch result {
                case .success(_):
                    response.success(.noContent)
                case .failure(let err):
                    response.systemError(error: "\(request.head.uri) \(request.head.method): \(err.localizedDescription)")
                }
            }
        }
    }
}
