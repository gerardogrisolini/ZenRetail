//
//  Seo.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 29/11/17.
//

import Foundation
import ZenPostgres

class Seo: PostgresJson {
    public var permalink : String = ""
    public var title : [Translation] = [Translation]()
    public var description : [Translation] = [Translation]()
    
    public var json: String {
        let json = try! JSONEncoder().encode(self)
        return String(data: json, encoding: .utf8)!
    }
}

