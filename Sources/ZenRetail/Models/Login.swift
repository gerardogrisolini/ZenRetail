//
//  Login.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 25/10/17.
//

class LoginUser: Codable {
    public var username: String = ""
    public var password: String = ""
}

class LoginRegistry: Codable {
    public var email: String = ""
    public var password: String = ""
}
