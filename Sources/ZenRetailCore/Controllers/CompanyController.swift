//
//  CompanyController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 11/04/17.
//
//

import Foundation
import ZenNIO
import ZenSMTP
import SwiftGD

class CompanyController {
	
    init(router: Router) {
        router.get("/api/company", handler: companyHandlerGET)
		router.post("/api/company", handler: companyHandlerPOST)
		router.post("/api/media", handler: uploadMediaHandlerPOST)
        router.post("/api/medias", handler: uploadMediasHandlerPOST)
        router.post("/api/email", handler: emailHandlerPOST)
        
        router.get("/media/:filename", handler: {
            request, response in
            self.getFile(request, response, .big)
        })
        router.get("/thumb/:filename", handler: {
            request, response in
            self.getFile(request, response, .small)
        })
        router.get("/csv/:filename", handler: {
            request, response in
            self.getFile(request, response, .big)
        })
	}
	
    func companyHandlerGET(request: HttpRequest, response: HttpResponse) {
		do {
			let item = Company()
            try item.select()
			try response.send(json:item)
			response.completed()
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
	
	func companyHandlerPOST(request: HttpRequest, response: HttpResponse) {
		do {
            guard let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(Company.self, from: data)
			try item.save()
			try response.send(json:item)
			response.completed( .created)
		} catch {
			response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
		}
	}
    
    fileprivate func getFile(_ request: HttpRequest, _ response: HttpResponse, _ size: MediaSize) {
        let file = File()
        if let filename = request.getParam(String.self, key: "filename") {
            if let data = try? file.getData(filename: filename, size: size) {
                response.addHeader(.contentType, value: file.fileContentType)
                response.send(data: data)
                response.completed()
                return
            }
        }

        response.completed( .notFound)
    }
 
    fileprivate func saveFiles(_ fileName: String, _ data: Data) throws -> Media {
        let media = Media()
        media.contentType = fileName.contentType
        media.name = fileName
        
        let big = File()
        big.fileName = media.name
        big.fileContentType = media.contentType
        big.setData(data: data)
        try big.save()
        
        let image = try Image(data: data)
        if let thumb = image.resizedTo(width: 380) {
            let small = File()
            small.fileName = media.name
            small.fileContentType = media.contentType
            small.setData(data: try thumb.export())
            try small.save()
        }

        return media
    }
    
    fileprivate func saveFile(_ fileName: String, _ data: Data) throws -> Media {
        let media = Media()
        media.contentType = fileName.contentType
        media.name = fileName
        
        let big = File()
        try big.get("fileName", media.name)
        big.fileName = media.name
        big.fileContentType = media.contentType
        big.setData(data: data)
        try big.save()
        
        return media
    }

    func uploadMediaHandlerPOST(request: HttpRequest, response: HttpResponse) {
        do {
            guard let fileName = request.getParam(String.self, key: "file[]"),
                let file = request.getParam(Data.self, key: fileName) else {
                throw HttpError.badRequest
            }

            let media = try saveFile(fileName, file)
            print("Uploaded file \(fileName) => \(media.name)")
            try response.send(json:media)
            response.completed( .created)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }

    func uploadMediasHandlerPOST(request: HttpRequest, response: HttpResponse) {
        do {
            guard let fileNames = request.getParam(String.self, key: "file[]") else {
                throw HttpError.badRequest
            }

            var medias = [Media]()
            for fileName in fileNames.split(separator: ",") {
                if let data = request.getParam(Data.self, key: fileName.description) {
                    let media = try saveFiles(fileName.description, data)
                    medias.append(media)
                    print("Uploaded file \(fileName) => \(media.name)")
                }
            }
            try response.send(json:medias)
            response.completed( .created)
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
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
            try company.select()
            if company.companyEmailInfo.isEmpty {
                throw HttpError.systemError(0, "email address from is empty")
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
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
}
