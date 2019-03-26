//
//  Result.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 27/05/18.
//

import Foundation

struct Result: Codable {
    public var added: Int = 0
    public var updated: Int = 0
    public var deleted: Int = 0
    public var articles : [Article] = [Article]()
}
