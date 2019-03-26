//
//  Tax.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 21/11/17.
//

import ZenPostgres

class Tax: PostgresJson {
    public var name: String = ""
    public var value: Int = 0
    
    convenience init(name: String, value: Int) {
        self.init()
        
        self.name = name
        self.value = value
    }
}

