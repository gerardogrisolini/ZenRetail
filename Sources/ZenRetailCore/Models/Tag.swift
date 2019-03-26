//
//  Tag.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 07/11/17.
//

import ZenPostgres

class Tag: PostgresJson, Comparable {
    public var groupId : Int = 0
    public var valueId : Int = 0
    public var valueName : String = ""

    static func <(lhs: Tag, rhs: Tag) -> Bool {
        return lhs.groupId < rhs.groupId && lhs.valueId < rhs.valueId
    }
    
    static func ==(lhs: Tag, rhs: Tag) -> Bool {
        return lhs.groupId == rhs.groupId && lhs.valueId == rhs.valueId
    }
}

