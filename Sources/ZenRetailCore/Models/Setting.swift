//
//  Setting.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 06/12/17.
//

import Foundation

struct Setting: Codable {
    
    public var companyId : Int = 0
    public var companyName : String = ""
    public var companyAddress : String = ""
    public var companyCity : String = ""
    public var companyZip : String = ""
    public var companyProvince : String = ""
    public var companyCountry : String = ""
    public var companyVatNumber : String = ""
    public var companyPhone : String = ""
    public var companyEmailInfo : String = ""
    public var companyEmailSales : String = ""
    public var companyEmailSupport : String = ""
    public var companyWebsite : String = ""
    public var companyCurrency : String = ""
    public var companyUtc : String = ""

    public var homeFeatured : Bool = true
    public var homeNews : Bool = true
    public var homeDiscount : Bool = true
    public var homeCategory : Bool = true
    public var homeBrand : Bool = true
    
    public var homeSeo : Seo = Seo()
    public var homeContent: [Translation] = [Translation]()
    public var infoSeo : Seo = Seo()
    public var infoContent: [Translation] = [Translation]()

    public var bankName : String = ""
    public var bankIban : String = ""
    public var paypalEnv : String = ""
    public var paypalSandbox : String = ""
    public var paypalProduction : String = ""
    public var cashOnDelivery : Bool = false

    public var shippingStandard : Bool = false
    public var shippingExpress : Bool = false
}
