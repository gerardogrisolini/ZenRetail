//
//  Configuration.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 05/05/18.
//

import Foundation

class Configuration: Codable {

    var serverName: String
    var serverPort: Int
    let serverSSLPort: Int
    let sslCert: String
    let sslKey: String
    let documentRoot: String

    var postgresHost: String
    var postgresDatabase: String
    var postgresUsername: String
    var postgresPassword: String
    var postgresPort: Int

    init() {
        self.serverName = "localhost"
        self.serverPort = 8080
        self.serverSSLPort = 0
        self.documentRoot = "./webroot"
        self.sslCert = "" //certificate.crt
        self.sslKey = "" //private.pem

        self.postgresHost = "localhost"
        self.postgresDatabase = "webretail"
        self.postgresUsername = "postgres"
        self.postgresPassword = "zBnwEe8QDR"
        self.postgresPort = 5432
    }
}
