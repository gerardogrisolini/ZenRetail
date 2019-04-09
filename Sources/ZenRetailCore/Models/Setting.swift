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

    public var companyDescription : [Translation] = [Translation]()
    public var companyHomeSeo : Seo = Seo()
    public var companyInfoSeo : Seo = Seo()

    public var companyPhone : String = ""
    public var companyEmailInfo : String = ""
    public var companyEmailSales : String = ""
    public var companyEmailSupport : String = ""
    
    public var companyWebsite : String = ""
    public var companyCurrency : String = ""
    public var companyUtc : String = ""

    public var bankName : String = ""
    public var bankIban : String = ""
    public var paypalEnv : String = ""
    public var paypalSandbox : String = ""
    public var paypalProduction : String = ""
    public var cashOnDelivery : Bool = false

    public var shippingStandard : Bool = false
    public var shippingExpress : Bool = false
}
