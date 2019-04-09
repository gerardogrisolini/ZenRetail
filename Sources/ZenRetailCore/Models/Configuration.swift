//
//  Configuration.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 05/05/18.
//

import Foundation
import ZenNIO

class Configuration: Codable {

    var serverName: String
    var serverPort: Int
    let sslCert: String
    let sslKey: String
    let httpVersion: Int
    let documentRoot: String
    
    var postgresHost: String
    var postgresDatabase: String
    var postgresUsername: String
    var postgresPassword: String
    var postgresPort: Int

    init() {
        self.serverName = "localhost"
        self.serverPort = 8888
        self.sslCert = "" //cert.crt
        self.sslKey = "" //key.pem
        self.httpVersion = 1
        self.documentRoot = "webroot"
        
        self.postgresHost = "localhost"
        self.postgresDatabase = "webretail"
        self.postgresUsername = "postgres"
        self.postgresPassword = "zBnwEe8QDR"
        self.postgresPort = 5432
    }
}
