//
//  Configuration.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 05/05/18.
//

import Foundation
import ZenNIO
import Logging

class Configuration: Codable {
    var serverHost: String
    var serverPort: Int
    let sslCert: String
    let sslKey: String
    let httpVersion: Int
    let documentRoot: String
    let logLevel: Logger.Level
    
    var postgresHost: String
    var postgresDatabase: String
    var postgresUsername: String
    var postgresPassword: String
    var postgresPort: Int
    var postgresTsl: Bool
    var postgresMaxConn: Int
    
    init() {
        serverHost = "localhost"
        serverPort = 8888
        sslCert = "" //cert.crt
        sslKey = "" //key.pem
        httpVersion = 1
        documentRoot = "webroot"
        logLevel = .info
        
        postgresHost = "localhost"
        postgresDatabase = "zenretail"
        postgresUsername = "postgres"
        postgresPassword = "zBnwEe8QDR"
        postgresPort = 5432
        postgresTsl = false
        postgresMaxConn = 20
    }
    
    var serverUrl: String {
        let port = serverPort != 80 && serverPort != 443
            ? ":\(serverPort)"
            : ""
        return "\(sslCert.isEmpty ? "http" : "https")://\(serverHost)\(port)"
    }
}
