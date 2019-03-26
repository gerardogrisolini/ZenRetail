//
//  Period.swift
//  macWebretail
//
//  Created by Gerardo Grisolini on 19/06/17.
//  Copyright © 2017 Gerardo Grisolini. All rights reserved.
//

class Period: Codable {
    
    public var start : Int = 0
    public var finish : Int = 0

    private enum CodingKeys: String, CodingKey {
        case start
        case finish
    }
    
    required init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        start = try container.decode(String.self, forKey: .start).DateToInt()
        finish = try container.decode(String.self, forKey: .finish).DateToInt()
    }
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(start, forKey: .start)
        try container.encode(finish, forKey: .finish)
    }
}

