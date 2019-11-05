//
//  Extensions.swift
//  ZenRetail
//
//  Created by Gerardo Grisolini on 23/03/2019.
//

import Foundation
import ZenNIO
import ZenMWS
import CryptoSwift
import ZenPostgres

extension Int {
    static func now() -> Int {
        return Int(Date.timeIntervalSinceReferenceDate)
    }
    
    func formatDateShort() -> String {
        return formatDate(format: "yyyy-MM-dd")
    }
    
    func formatDate(format: String = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") -> String {
        if self == 0 { return "" }
        let date = Date(timeIntervalSinceReferenceDate: TimeInterval(self))
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: date)
    }
}

extension Date {
    func formatDate(format: String = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: self)
    }
}

extension Double {
    func roundCurrency() -> Double {
        return (self * 100).rounded() / 100
    }

    func formatCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2;
        formatter.locale = Locale.current
        let result = formatter.string(from: NSNumber(value: self))
        
        return result!
    }
}

extension String {
    func DateToInt() -> Int {
        if self.isEmpty {
            return 0
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = self.count > 10 ? "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'" : "yyyy-MM-dd"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let date = formatter.date(from: self)!
        
        return Int(date.timeIntervalSinceReferenceDate)
    }
    
    func permalink() -> String {
        let data = self
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .lowercased()
        return data
    }
    
    func uniqueName() -> String {
        let extensionPosition = self.lastIndex(of: ".")!
        let stripExtension = String(self[extensionPosition...])
        return UUID().uuidString + stripExtension
    }
    
    func checkdigit() -> String {
        if self.count != 12 {
            print("error the lenght must be 12 numbers")
        }
        
        let array = [1,3,1,3,1,3,1,3,1,3,1,3]
        var sum = 0
        for i in 0...11 {
            let index = self.index(self.startIndex, offsetBy: i)
            sum += Int(String(self[index]))! * array[i]
        }
        var count = 0
        while count < sum {
            count += 10
        }
        return "\(self)\(count - sum)"
    }

//    #if os(OSX)
//    func toBarcode() -> NSImage? {
//        let data = self.data(using: String.Encoding.ascii)
//
//        if let filter = CIFilter(name: "CICode128BarcodeGenerator") {
//            filter.setValue(data, forKey: "inputMessage")
//            let transform = CGAffineTransform(scaleX: 4, y: 5)
//
//            if let output = filter.outputImage?.transformed(by: transform) {
//                let rep = NSCIImageRep(ciImage: output)
//                let nsImage = NSImage(size: rep.size)
//                //let nsImage = NSImage(size: NSSize(width: self.collectionView.bounds.width - 40, height: 100.0))
//                nsImage.addRepresentation(rep)
//
//                return nsImage
//            }
//        }
//        return nil
//    }
//    #endif

    var encrypted: String {
        let password: Array<UInt8> = Array(self.utf8)
        let salt: Array<UInt8> = Array("ZenRetail".utf8)
        let key = try! PKCS5.PBKDF2(password: password, salt: salt, iterations: 4096, variant: .sha256).calculate()
        return key.toBase64()!
    }
}

//extension PostgresData {
//    public var boolean: Bool? {
//        guard var value = self.value else {
//            return nil
//        }
//        guard value.readableBytes == 1 else {
//            return nil
//        }
//        guard let byte = value.readInteger(as: UInt8.self) else {
//            return nil
//        }
//        
//        switch self.formatCode {
//        case .text:
//            switch byte {
//            case Character("t").asciiValue!:
//                return true
//            case Character("f").asciiValue!:
//                return false
//            default:
//                return nil
//            }
//        case .binary:
//            switch byte {
//            case 1:
//                return true
//            case 0:
//                return false
//            default:
//                return nil
//            }
//        }
//    }
//}

extension Sequence {
    func groupBy<G: Hashable>(closure: (Iterator.Element)->G) -> [G: [Iterator.Element]] {
        var results = [G: Array<Iterator.Element>]()
        forEach {
            let key = closure($0)
            if var array = results[key] {
                array.append($0)
                results[key] = array
            }
            else {
                results[key] = [$0]
            }
        }
        return results
    }
}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var alreadyAdded = Set<Iterator.Element>()
        return self.filter { alreadyAdded.insert($0).inserted }
    }
}

extension Array where Element: Comparable {
    func containsSameElements(as other: [Element]) -> Bool {
        return self.count == other.count && self.sorted() == other.sorted()
    }
}

extension HttpRequest {
    func isAuthenticated() -> Bool {
        if self.isAuthenticated { return true }
        let info = self.authorization.replacingOccurrences(of: "Basic ", with: "").split(separator: "#")
        let deviceName = info.first?.description ?? ""
        let deviceToken = info.last?.description ?? ""
        
        let device = Device()
        try? device.get(token: deviceToken, name: deviceName)
        return device.idStore > 0
    }
}

extension HttpResponse {
    struct JsonError: Codable {
        let status: Int
        let error: String
    }
    public func badRequest(error: String) {
        print(error)
        try? self.send(json: JsonError(status: 400, error: error))
        self.completed(.badRequest)
    }
    public func systemError(error: String) {
        print(error)
        try? self.send(json: JsonError(status: 500, error: error))
        self.completed(.internalServerError)
    }
}

extension Array where Element:Translation {
    func defaultValue() -> String {
        if let translation = self.first(where:{ $0.country == "EN" }) {
            return translation.value
        }
        if let translation = self.first {
            return translation.value
        }
        return ""
    }

    func valueOrDefault(country: String, defaultValue: String = "") -> String {
        if let translation = self.first(where:{ $0.country == country }) {
            return translation.value
        }
        if let translation = self.first {
            return translation.value
        }
        return defaultValue
    }
}

// Amazon MWS

protocol EnumCollection : Hashable {}
extension EnumCollection {
    static func cases() -> AnySequence<Self> {
        typealias S = Self
        return AnySequence { () -> AnyIterator<S> in
            var raw = 0
            return AnyIterator {
                let current : Self = withUnsafePointer(to: &raw) { $0.withMemoryRebound(to: S.self, capacity: 1) { $0.pointee } }
                //guard current.hashValue == raw else { return nil }
                raw += 1
                return current
            }
        }
    }
}
extension ClothingType : EnumCollection { }

extension Product {
    
    func productFeed() -> ProductFeed {
        var messages: [ProductMessage] = [ProductMessage]()
        
        let material = self._attributes.first(where: { $0._attribute.attributeName == "Material" })?._attributeValues.first?._attributeValue.attributeValueName
        let colors = self._attributes.first(where: { $0._attribute.attributeName == "Color" })!._attributeValues
        let sizes = self._attributes.first(where: { $0._attribute.attributeName == "Size" })!._attributeValues
        var variationTheme: VariationTheme = .sizeColor
        if sizes.count == 0 { variationTheme = .color }
        if colors.count == 0 { variationTheme = .size }
        
        let category = self._categories.first(where: { $0._category.categoryIsPrimary })?._category.categoryName
        let department = self._categories.first(where: { !$0._category.categoryIsPrimary })?._category.categoryName
        let clothingType = ClothingType.init(rawValue: category ?? "Outerwear") ?? .outerwear
        
        if self._articles.count > 1 {
            
            messages.append(
                ProductMessage(
                    operationType: .update,
                    product: MwsProduct(
                        sku: self.productCode,
                        standardProductID: nil,
                        condition: Condition(conditionType: .new),
                        itemPackageQuantity: nil,
                        numberOfItems: nil,
                        descriptionData: DescriptionData(
                            title: self.productName,
                            brand: self._brand.brandName,
                            description: self.productDescription.defaultValue()
                        ),
                        productData: ProductData(
                            clothing: Clothing(
                                variationData: VariationData(
                                    parentage: .parent,
                                    size: nil,
                                    color: nil,
                                    variationTheme: variationTheme
                                ),
                                classificationData: ClassificationData(
                                    clothingType: clothingType,
                                    department: department ?? "",
                                    materialComposition: material ?? "",
                                    outerMaterial: material ?? "",
                                    colorMap: nil,
                                    sizeMap: nil
                                )
                            )
                        )
                    )
                )
            )
        }
        
        for article in self._articles {
            
            var sku = ""
            var title = ""
            var color: String?
            var size: String?
            var parentage: Parentage
            var standardProductID: StandardProductID?
            
            parentage = .child
            sku = article.articleNumber > 0 ? "\(self.productCode)-\(article.articleNumber)" : self.productCode
            title = self.productName
            
            guard let barcode = article.articleBarcodes
                .first(where: { $0.tags.contains(where: { $0.valueName == "Amazon" }) })?
                .barcode else {
                    continue
            }
            
            standardProductID = StandardProductID(type: .EAN, value: barcode)
            article._attributeValues.forEach({ (value) in
                if let s = sizes.first(where: { $0.attributeValueId == value.attributeValueId })?._attributeValue.attributeValueName {
                    size = s
                }
                if let c = colors.first(where: { $0.attributeValueId == value.attributeValueId })?._attributeValue.attributeValueName {
                    color = c
                }
            })
            
            if size != nil && color != nil {
                title += " (\(size!), \(color!))"
            } else if size != nil {
                title += " (\(size!))"
            } else if color != nil {
                title += " (\(color!))"
            }
            
            let productData = ProductData(
                clothing: Clothing(
                    variationData: VariationData(
                        parentage: parentage,
                        size: size,
                        color: color,
                        variationTheme: variationTheme
                    ),
                    classificationData: ClassificationData(
                        clothingType: clothingType,
                        department: department ?? "",
                        materialComposition: material ?? "",
                        outerMaterial: material ?? "",
                        colorMap: color,
                        sizeMap: size
                    )
                )
            )
            
            messages.append(
                ProductMessage(
                    operationType: .update,
                    product: MwsProduct(
                        sku: sku,
                        standardProductID: standardProductID ?? nil,
                        condition: Condition(conditionType: .new),
                        itemPackageQuantity: 1,
                        numberOfItems: 1,
                        descriptionData: DescriptionData(
                            title: title,
                            brand: self._brand.brandName,
                            description: self.productDescription.defaultValue()
                        ),
                        productData: productData
                    )
                )
            )
        }
        
        return ProductFeed(
            purgeAndReplace: true,
            messages: messages
        )
    }
    
    func relationshipFeed() -> RelationshipFeed {
        
        var relations: [Relation] = [Relation]()
        for article in self._articles {
            if article.articleBarcodes.first(where: { $0.tags.contains(where: { $0.valueName == "Amazon" }) }) == nil {
                continue
            }
            relations.append(
                Relation(
                    sku: article.articleNumber > 0 ? "\(self.productCode)-\(article.articleNumber)" : self.productCode,
                    type: .variation
                )
            )
        }
        
        let messages = [
            RelationshipMessage(
                operationType: .update,
                relationship: Relationship(
                    parentSKU: self.productCode,
                    relation: relations
                )
            )
        ]
        
        return RelationshipFeed(
            purgeAndReplace: true,
            messages: messages
        )
    }
    
    func imageFeed() -> ImageFeed {
        
        var messages = [ImageMessage]()
        
        self._articles.forEach { (article) in
            
            var imageType: ImageType = .main
            self.productMedia.forEach { (media) in
                
                messages.append(
                    ImageMessage(
                        operationType: .update,
                        productImage:
                        ProductImage(
                            sku: article.articleNumber > 0 ? "\(self.productCode)-\(article.articleNumber)" : self.productCode,
                            imageType: imageType,
                            imageLocation: "\(ZenRetail.config.serverUrl)/media/\(media.name)"
                        )
                    )
                )
                switch imageType {
                case .main:
                    imageType = .pt1
                case .pt1:
                    imageType = .pt2
                case .pt2:
                    imageType = .pt3
                case .pt3:
                    imageType = .pt4
                case .pt4:
                    imageType = .pt5
                case .pt5:
                    imageType = .pt6
                case .pt6:
                    imageType = .pt7
                case .pt7:
                    imageType = .pt8
                default:
                    return
                }
            }
        }
        
        return ImageFeed(
            purgeAndReplace: true,
            messages: messages
        )
    }
    
    func priceFeed() -> PriceFeed {
        
        var messages = [PriceMessage]()
        for article in self._articles {
            guard let barcode = article.articleBarcodes
                .first(where: { $0.tags.contains(where: { $0.valueName == "Amazon" }) }) else {
                    continue
            }
            
            var salePrice: SalePrice?
            if let discount = barcode.discount {
                salePrice = SalePrice(
                    price: Float(discount.discountPrice),
                    currency: .eur,
                    startDate: Date(timeIntervalSinceReferenceDate: TimeInterval(discount.discountStartAt)),
                    endDate: Date(timeIntervalSinceReferenceDate: TimeInterval(discount.discountFinishAt))
                )
            }
            
            messages.append(
                PriceMessage(
                    operationType: .update,
                    price: MwsPrice(
                        sku: article.articleNumber > 0 ? "\(self.productCode)-\(article.articleNumber)" : self.productCode,
                        standardPrice: StandardPrice(price: Float(self.productPrice.selling), currency: .eur),
                        salePrice: salePrice
                    )
                )
            )
        }
        
        return PriceFeed(
            purgeAndReplace: true,
            messages: messages
        )
    }
    
    func inventoryFeed() -> InventoryFeed? {
        
        var messages = [InventoryMessage]()
        for article in self._articles {
            
            if article.articleUpdated < self.productAmazonUpdated ||
                article.articleBarcodes.first(where: { $0.tags.contains(where: { $0.valueName == "Amazon" }) }) == nil {
                continue
            }
            
            let quantity = article._quantity - article._booked
            messages.append(
                InventoryMessage(
                    operationType: .update,
                    inventory: Inventory(
                        sku: article.articleNumber > 0 ? "\(self.productCode)-\(article.articleNumber)" : self.productCode,
                        quantity: Int(quantity)
                    )
                )
            )
        }
        
        return messages.count == 0
            ? nil
            : InventoryFeed(
                purgeAndReplace: true,
                messages: messages
        )
    }
}

