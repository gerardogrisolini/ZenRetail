//
//  Whouse.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 28/05/18.
//

import Foundation

struct Whouse: Codable {
    public var id: Int = 0
    public var sku: String = ""
    public var name: String = ""
    public var loaded: Double = 0.0
    public var unloaded: Double = 0.0
    public var stock: Double = 0.0
}
