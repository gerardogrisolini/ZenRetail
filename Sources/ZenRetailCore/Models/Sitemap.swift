//
//  Sitemap.swift
//  ZenRetailCore
//
//  Created by Gerardo Grisolini on 14/04/2019.
//

import Foundation
import AEXML

public enum SitemapChangeFrequency: String {
    case always, hourly, daily, weekly, monthly, yearly, never
}

public struct SitemapItem
{
    /// <summary>
    /// URL of the page.
    /// </summary>
    var url: String
    
    /// <summary>
    /// The date of last modification of the file.
    /// </summary>
    var lastModified: Date?
    
    /// <summary>
    /// How frequently the page is likely to change.
    /// </summary>
    var changeFrequency: SitemapChangeFrequency?
    
    /// <summary>
    /// The priority of this URL relative to other URLs on your site. Valid values range from 0.0 to 1.0.
    /// </summary>
    var priority: Double?
    
    init(url: String, lastModified: Date? = nil, changeFrequency: SitemapChangeFrequency? = nil, priority: Double? = nil) {
        self.url = url
        self.lastModified = lastModified
        self.changeFrequency = changeFrequency
        self.priority = priority
    }
}

public struct Sitemap
{
    let items: [SitemapItem]
    
    init(items: [SitemapItem]) {
        self.items = items
    }

    var xmlString: String {
        return self.xml().xml
    }
    
    func xml() -> AEXMLDocument {

        let map = AEXMLDocument()
        let attributes = [
            "xmlns" : "http://www.sitemaps.org/schemas/sitemap/0.9",
            "xmlns:xsi" : "http://www.w3.org/2001/XMLSchema-instance",
            "xsi:schemaLocation": "http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd"
        ]
        let content = map.addChild(name: "urlset", attributes: attributes)
        
        for item in items {
            let url = content.addChild(name: "url")
            url.addChild(name: "loc", value: item.url)
            url.addChild(name: "lastmod", value: item.lastModified?.formatDate(format: "yyyy-MM-dd"))
            url.addChild(name: "changefreq", value: item.changeFrequency?.rawValue)
            let priority = item.priority != nil ? String(format:"%.1f", item.priority!) : nil
            url.addChild(name: "priority", value: priority)
        }
        
        //print(map.xml)
        return map
    }
}
