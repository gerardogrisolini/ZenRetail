//
//  OrderModel.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 18/11/17.
//

struct OrderModel: Codable {
    public var shipping : String = ""
    public var shippingCost : Double = 0.0
    public var payment : String = ""
    public var paypal : String = ""
}

