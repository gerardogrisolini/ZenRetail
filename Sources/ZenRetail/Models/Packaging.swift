//
//  Packaging.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 21/11/17.
//

import ZenPostgres

class Packaging: PostgresJson {
    public var weight : Double = 0.0
    public var length : Double = 0.0
    public var width : Double = 0.0
    public var height : Double = 0.0
    
    func isEmpty() -> Bool {
        return weight + length + width + height == 0
    }
}

