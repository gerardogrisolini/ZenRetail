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
import SwiftGD


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
//        router.get("/csv/:filename", handler: {
//            request, response in
//            self.getFile(request, response, .csv)
//        })
    }
    
    
//    fileprivate func getFile(_ request: HttpRequest, _ response: HttpResponse, _ size: MediaType) {
//        
//        let file = File()
//        if let filename: String = request.getParam("filename"),
//            let data = try? file.getData(filename: filename, size: size) {
//                response.addHeader(.contentType, value: file.fileContentType)
//                response.send(data: Data(data))
//                response.completed()
//        } else {
//            response.completed( .notFound)
//        }
//    }

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
                    let thumb = try? Image(data: data).resizedTo(width: 380),
                    let export = try? thumb.export() {
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
                    response.completed()
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
                    response.completed()
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
                response.completed( .created)
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
                        response.completed(.created)
                    }
                }
            }
        }
    }

    func emailHandlerPOST(request: HttpRequest, response: HttpResponse) {
        do {
            guard let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(PdfDocument.self, from: data)
            if item.address.isEmpty {
                throw HttpError.systemError(0, "email address to is empty")
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
                
                ZenSMTP.shared.send(email: email) { error in
                    if let error = error {
                        print(error)
                        response.completed(.internalServerError)
                    } else {
                        response.completed(.noContent)
                    }
                }
            }
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
}
