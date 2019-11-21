//
//  BarcodeController.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 03/06/17.
//
//

import Foundation
import ZenNIO
import ZenSMTP


class PdfController {
    
    private let movementRepository: MovementArticleProtocol
    
    init(router: Router) {
        self.movementRepository = ZenIoC.shared.resolve() as MovementArticleProtocol

        router.post("/api/pdf", handler: pdfHandlerPOST)
        router.post("/api/pdf/email", handler: emailHandlerPOST)
//        router.get("/api/pdf/barcode/:id", handler: barcodeHandlerGET)
    }
    
    func pdfHandlerPOST(request: HttpRequest, response: HttpResponse) {
        request.eventLoop.execute {
            do {
                guard let data = request.bodyData else {
                    throw HttpError.badRequest
                }
                let item = try JSONDecoder().decode(PdfDocument.self, from: data)
                
                let pdf = Utils.htmlToPdf(model: item);
                guard let content = pdf else {
                    throw HttpError.systemError(0, "phantomjs error")
                }
                
                response.addHeader(.contentType, value: "application/pdf")
                response.send(data: content)
                response.completed()
            } catch {
                response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }
    
    func emailHandlerPOST(request: HttpRequest, response: HttpResponse) {
        guard let data = request.bodyData,
            let item = try? JSONDecoder().decode(PdfDocument.self, from: data),
            !item.address.isEmpty else {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): body data")
                return
        }

        let company = Company()
        company.select().whenComplete { _ in
            do {
                if company.companyEmailInfo.isEmpty {
                    throw HttpError.systemError(0, "email address from is empty")
                }
                
                guard let pdf = Utils.htmlToPdf(model: item) else {
                    throw HttpError.systemError(0, "phantomjs error")
                }
                
                let email = Email(
                    fromName: company.companyName,
                    fromEmail: company.companyEmailSupport,
                    toName: nil,
                    toEmail: item.address,
                    subject: item.subject,
                    body: item.content,
                    attachments: [
                        Attachment(
                            fileName: item.subject,
                            contentType: "application/pdf",
                            data: pdf
                        )
                    ]
                )
                
                ZenSMTP.mail.send(email: email).whenComplete { result in
                    switch result {
                    case .success(_):
                        item.content = "Email successfully sent"
                        try? response.send(json: item)
                        response.completed(.accepted)
                    case .failure(let err):
                        response.systemError(error: "\(request.head.uri) \(request.head.method): \(err)")
                    }
                }

            } catch {
                response.systemError(error: "\(request.head.uri) \(request.head.method): \(error)")
            }
        }
    }
}

