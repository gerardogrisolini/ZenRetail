//
//  Email.swift
//  Webretail
//
//  Created by Gerardo Grisolini on 12/04/17.
//
//

class PdfDocument: Codable {
	public var address : String = ""
	public var subject : String = ""
	public var content : String = ""
    public var size : String = "A4"
    public var zoom : String = "1.0"
}
