//
//  Barcode.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 04/11/17.
//

import ZenPostgres

class Barcode: PostgresJson {
    
    public var barcode : String = ""
    public var tags : [Tag] = [Tag]()
    public var price : Price? = nil
    public var discount : Discount? = nil

    private enum CodingKeys: String, CodingKey {
        case barcode
        case tags
        case price
        case discount
    }

    init() { }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        barcode = try container.decodeIfPresent(String.self, forKey: .barcode) ?? ""
        tags = try container.decodeIfPresent([Tag].self, forKey: .tags) ?? [Tag]()
        price = try container.decodeIfPresent(Price.self, forKey: .price) ?? nil
        discount = try container.decodeIfPresent(Discount.self, forKey: .discount) ?? nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(barcode, forKey: .barcode)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(price, forKey: .price)
        try container.encodeIfPresent(discount, forKey: .discount)
    }
}

