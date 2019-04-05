//
//  DocumentRepository.swift
//  ZenRetailCore
//
//  Created by Gerardo Grisolini on 03/04/2019.
//

import Foundation

struct Utils {
    
    static func htmlToPdf(model: PdfDocument) -> Data? {
        if let zennio = ZenRetail.zenNIO {
            let header = "http\(zennio.port == 443 ? "s" : "")://localhost:\(zennio.port)/media/header.png"
            model.content = model.content.replacingOccurrences(of: "/media/header.png", with: header)
            //model.content = model.content.replacingOccurrences(of: "Header not found. Upload on Settings -> Company -> Document Header", with: header)
        }
        
        let path = NSTemporaryDirectory() as String
        let pathOutput = "\(path)\(model.subject)";
        
        guard self.execCommand(
            command: "phantomjs",
            args: [
                "--output-encoding=utf8",
                "--script-encoding=utf8",
                "--ignore-ssl-errors=yes",
                "--load-images=yes",
                "--local-to-remote-url-access=yes",
                "rasterize.js",
                "'\(model.content)'",
                pathOutput,
                model.size
            ]) != nil else {
                return nil
        }
        
        let content = FileManager.default.contents(atPath: pathOutput)
        try? FileManager.default.removeItem(atPath: pathOutput)
        return content
    }
    
    static func execCommand(command: String, args: [String]) -> String? {
        let envs = ["/bin", "/sbin", "/usr/sbin", "/usr/bin", "/usr/local/bin"]
        let fileManager = FileManager.default
        var launchPath = command
        if launchPath.first != "/" {
            for env in envs {
                let path = "\(env)/\(launchPath)"
                if fileManager.fileExists(atPath: path) {
                    launchPath = path
                }
            }
        }
        if launchPath.first != "/" {
            return nil
        }
        
        //print("shell: \(launchPath) \(arguments.joined(separator: " "))")
        if !fileManager.fileExists(atPath: launchPath) {
            return nil
        }
        
        let task = Process()
        task.launchPath = launchPath
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: String.Encoding.utf8) {
            return output
        }
        
        return ""
    }
}
