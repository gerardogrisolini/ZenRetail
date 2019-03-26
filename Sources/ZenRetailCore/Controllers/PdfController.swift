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
//        router.get("/api/pdf/barcode/{id}", handler: barcodeHandlerGET)
    }
    
    func pdfHandlerPOST(request: HttpRequest, response: HttpResponse) {
        do {
            guard let data = request.bodyData else {
                throw HttpError.badRequest
            }
            let item = try JSONDecoder().decode(PdfDocument.self, from: data)
            
            let pdf = self.htmlToPdf(model: item);
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
            
            guard let pdf = self.htmlToPdf(model: item) else {
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
            
            ZenSMTP.shared.send(email: email) { error in
                if let error = error {
                    response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
                } else {
                    item.content = "Email successfully sent"
                    try? response.send(json:item)
                    response.completed( .accepted)
                }
            }
            
        } catch {
            response.badRequest(error: "\(request.head.uri) \(request.head.method): \(error)")
        }
    }
    
    func htmlToPdf(model: PdfDocument) -> Data? {
        //let header = "http://\(server.serverName)/media/header.png"
        let header = "http\(ZenRetail.zenNIO.port == 443 ? "s" : "")://\(ZenRetail.zenNIO.host):\(ZenRetail.zenNIO.port)/media/header.png"
        model.content = model.content.replacingOccurrences(of: "/media/header.png", with: header)
        model.content = model.content.replacingOccurrences(of: "Header not found. Upload on Settings -> Company -> Document Header", with: header)
        
        let pathOutput = "/tmp/\(model.subject)";
        
        let result = self.execCommand(
            command: "phantomjs",
            args: [
                "--output-encoding=utf8",
                "--script-encoding=utf8",
                "--ignore-ssl-errors=yes",
                "--load-images=yes",
                "--local-to-remote-url-access=yes",
                "rasterize.js",
                model.content,
                pathOutput,
                model.size
            ])
        
        if !result.isEmpty {
            print(result);
            return nil;
        }

        let content = FileManager.default.contents(atPath: pathOutput)
        try? FileManager.default.removeItem(atPath: pathOutput)
        return content
    }

    func execCommand(command: String, args: [String]) -> String {
        if !command.hasPrefix("/") {
            let commandFull = execCommand(command: "/usr/bin/which", args: [command]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return execCommand(command: commandFull, args: args)
        } else {
            let proc = Process()
            proc.launchPath = command
            proc.arguments = args
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.launch()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: String.Encoding.utf8)!
        }
    }
}
