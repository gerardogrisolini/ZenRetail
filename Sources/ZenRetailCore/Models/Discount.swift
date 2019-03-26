//
//  Discount.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 30/03/17.
//
//

import ZenPostgres

class Discount: PostgresJson {
	
	public var discountPercentage : Int = 0
	public var discountPrice : Double = 0
	public var discountStartAt : Int = 0
	public var discountFinishAt : Int = 0
	
    public var _discountStartAt: String {
        return discountStartAt.formatDateShort()
    }
    
    public var _discountFinishAt: String {
        return discountFinishAt.formatDateShort()
    }

    private enum CodingKeys: String, CodingKey {
        case discountPercentage = "percentage"
        case discountPrice = "price"
        case discountStartAt = "startAt"
        case discountFinishAt = "finishAt"
    }

    init() {
    }
 
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        discountPercentage = try container.decodeIfPresent(Int.self, forKey: .discountPercentage) ?? 0
        discountPrice = try container.decodeIfPresent(Double.self, forKey: .discountPrice) ?? 0.0
        discountStartAt = try container.decodeIfPresent(String.self, forKey: .discountStartAt)?.DateToInt() ?? 0
        discountFinishAt = try container.decodeIfPresent(String.self, forKey: .discountFinishAt)?.DateToInt() ?? 0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(discountPercentage, forKey: .discountPercentage)
        try container.encode(discountPrice, forKey: .discountPrice)
        try container.encode(_discountStartAt, forKey: .discountStartAt)
        try container.encode(_discountFinishAt, forKey: .discountFinishAt)
    }
	
	func makeDiscount(sellingPrice: Double) {
		if self.discountPercentage > 0 {
			self.discountPrice = sellingPrice - (sellingPrice * Double(self.discountPercentage) / 100)
		} else if self.discountPrice > 0 {
			self.discountPercentage = Int((sellingPrice - self.discountPrice) / sellingPrice * 100.0)
		}
	}
}
