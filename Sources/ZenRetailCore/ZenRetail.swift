//
//  ZenRetail.swift
//  ZenRetail
//
//  Created by Gerardo Grisolini on 23/03/2019.
//

import Foundation
import ZenNIO
import ZenNIOSSL
import ZenNIOH2
import ZenSMTP
import ZenPostgres


public class ZenRetail {
    static var config: Configuration!
    static var zenNIO: ZenNIO!
    var zenPostgres: ZenPostgres!
    var zenSMTP: ZenSMTP!
    let router = Router()
    
    public init() {
        setup()
    }

    deinit {
        stop()
    }

    public func start() throws {
        if ZenRetail.config.sslCert.isEmpty {
            ZenRetail.zenNIO = ZenNIO(host: "0.0.0.0", port: ZenRetail.config.serverPort, router: router)
        } else {
            let zenNIO = ZenRetail.config.httpVersion == 1
                ? ZenNIOSSL(host: "0.0.0.0", port: ZenRetail.config.serverPort, router: router)
                : ZenNIOH2(host: "0.0.0.0", port: ZenRetail.config.serverPort, router: router)
            try zenNIO.addSSL(
                certFile: ZenRetail.config.sslCert,
                keyFile: ZenRetail.config.sslKey
            )
            ZenRetail.zenNIO = zenNIO
        }

        ZenRetail.zenNIO.addCORS()
        ZenRetail.zenNIO.addWebroot(path: ZenRetail.config.documentRoot)
        ZenRetail.zenNIO.addAuthentication(handler: { (username, password) -> (String?) in
            do {
                let user = User()
                try user.get(usr: username, pwd: password)
                return user.uniqueID
            } catch {
                do {
                    let registry = Registry()
                    try registry.get(email: username, pwd: password)
                    return registry.uniqueID
                } catch {
                    return nil
                }
            }
        })

        try setupDatabase()
        try createTables()
        try setupSmtp()
        
        addIoC()
        routesAndHandlers()
        addFilters()
        
        try ZenRetail.zenNIO.start()
    }

    public func stop() {
        try? zenSMTP?.close()
        try? zenPostgres?.close()
    }

    private func setup() {
        ZenRetail.config = loadConfiguration()
        
        if let serverName = ProcessInfo.processInfo.environment["HOST"] {
            ZenRetail.config.serverName = serverName
        }
        if let portString = ProcessInfo.processInfo.environment["PORT"] {
            ZenRetail.config.serverPort = Int(portString)!
        }
        if let databaseUrl = ProcessInfo.processInfo.environment["DATABASE_URL"] {
            parseConnectionString(databaseUrl: databaseUrl)
        }
    }
    
    private func setupSmtp() throws {
        let company = Company()
        try company.select()
        
        let config = ServerConfiguration(
            hostname: company.smtpHost,
            port: company.smtpSsl ? 587 : 25,
            username: company.smtpUsername,
            password: company.smtpPassword,
            cert: nil,
            key: nil
        )
        zenSMTP = try ZenSMTP(config: config)
    }
    
    private func parseConnectionString(databaseUrl: String) {
        var url = databaseUrl.replacingOccurrences(of: "postgres://", with: "")
        var index = url.index(before: url.firstIndex(of: ":")!)
        ZenRetail.config.postgresUsername = url[url.startIndex...index].description
        
        index = url.index(index, offsetBy: 2)
        var index2 = url.index(before: url.firstIndex(of: "@")!)
        ZenRetail.config.postgresPassword = url[index...index2].description
        
        index = url.index(index2, offsetBy: 2)
        url = url[index...].description
        
        index2 = url.index(before: url.firstIndex(of: ":")!)
        ZenRetail.config.postgresHost = url[url.startIndex...index2].description
        
        index = url.index(index2, offsetBy: 2)
        index2 = url.index(before: url.firstIndex(of: "/")!)
        ZenRetail.config.postgresPort = Int(url[index...index2].description)!
        
        index = url.index(index2, offsetBy: 2)
        ZenRetail.config.postgresDatabase = url[index...].description
    }
    
    private func setupDatabase() throws {
        
        let config = PostgresConfig(
            host: ZenRetail.config.postgresHost,
            port: ZenRetail.config.postgresPort,
//            tls: false,
            username: ZenRetail.config.postgresUsername,
            password: ZenRetail.config.postgresPassword,
            database: ZenRetail.config.postgresDatabase
        )
        zenPostgres = try ZenPostgres(config: config)
    }
 
    private func createTables() throws {
        let settings = Settings()
        try settings.create()
        let company = Company()
        try company.create()
        let file = File()
        try file.create()
        try file.setupShippingCost()
        let user = User()
        try user.create()
        try user.setAdmin()
        let causal = Causal()
        try causal.create()
        try causal.setupDefaults()
        let store = Store()
        try store.create()
        let brand = Brand()
        try brand.create()
        let category = Category()
        try category.create()
        //try category.setupMarketplace()
        let attribute = Attribute()
        try attribute.create()
        let attributeValue = AttributeValue()
        try attributeValue.create()
        try attribute.setupMarketplace()
        let tagGroup = TagGroup()
        try tagGroup.create()
        let tagValue = TagValue()
        try tagValue.create()
        //try tagGroup.setupMarketplace()
        let product = Product()
        try product.create()
        let productCategeory = ProductCategory()
        try productCategeory.create()
        let productAttribute = ProductAttribute()
        try productAttribute.create()
        let productAttributeValue = ProductAttributeValue()
        try productAttributeValue.create()
        let article = Article()
        try article.create()
        let articleAttributeValue = ArticleAttributeValue()
        try articleAttributeValue.create()
        let stock = Stock()
        try stock.create()
        let device = Device()
        try device.create()
        let registry = Registry()
        try registry.create()
        let invoice = Invoice()
        try invoice.create()
        let movement = Movement()
        try movement.create()
        let movementArticle = MovementArticle()
        try movementArticle.create()
        let publication = Publication()
        try publication.create()
        let basket = Basket()
        try basket.create()
        let amazon = Amazon()
        try amazon.create()
        let mwsRequest = MwsRequest()
        try mwsRequest.create()
    }
    
    private func addIoC() {
        ZenIoC.shared.register { UserRepository() as UserProtocol }
        ZenIoC.shared.register { CausalRepository() as CausalProtocol }
        ZenIoC.shared.register { StoreRepository() as StoreProtocol }
        ZenIoC.shared.register { DeviceRepository() as DeviceProtocol }
        ZenIoC.shared.register { BrandRepository() as BrandProtocol }
        ZenIoC.shared.register { CategoryRepository() as CategoryProtocol }
        ZenIoC.shared.register { AttributeRepository() as AttributeProtocol }
        ZenIoC.shared.register { AttributeValueRepository() as AttributeValueProtocol }
        ZenIoC.shared.register { TagGroupRepository() as TagGroupProtocol }
        ZenIoC.shared.register { TagValueRepository() as TagValueProtocol }
        ZenIoC.shared.register { ProductRepository() as ProductProtocol }
        ZenIoC.shared.register { ArticleRepository() as ArticleProtocol }
        ZenIoC.shared.register { RegistryRepository() as RegistryProtocol }
        ZenIoC.shared.register { MovementRepository() as MovementProtocol }
        ZenIoC.shared.register { MovementArticleRepository() as MovementArticleProtocol }
        ZenIoC.shared.register { InvoiceRepository() as InvoiceProtocol }
        ZenIoC.shared.register { StatisticRepository() as StatisticProtocol }
        ZenIoC.shared.register { PublicationRepository() as PublicationProtocol }
        ZenIoC.shared.register { EcommerceRepository() as EcommerceProtocol }
    }
    
    private func routesAndHandlers() {
        // Register Angular routes and handlers
        _ = AngularController(router: router)
        
        // Register api routes and handlers
        _ = CompanyController(router: router)
        _ = UserController(router: router)
        _ = CausalController(router: router)
        _ = StoreController(router: router)
        _ = DeviceController(router: router)
        _ = BrandController(router: router)
        _ = CategoryController(router: router)
        _ = AttributeController(router: router)
        _ = AttributeValueController(router: router)
        _ = TagGroupController(router: router)
        _ = TagValueController(router: router)
        _ = ProductController(router: router)
        _ = ArticleController(router: router)
        _ = RegistryController(router: router)
        _ = MovementController(router: router)
        _ = MovementArticleController(router: router)
        _ = InvoiceController(router: router)
        _ = PdfController(router: router)
        _ = StatisticController(router: router)
        _ = PublicationController(router: router)
        _ = EcommerceController(router: router)
        _ = AmazonController(router: router)
    }
    
    private func addFilters() {
        ZenRetail.zenNIO.setFilter(true, methods: [.GET, .POST, .PUT, .DELETE], url: "/api/*")
        ZenRetail.zenNIO.setFilter(false, methods: [.POST], url: "/api/login")
        ZenRetail.zenNIO.setFilter(false, methods: [.POST], url: "/api/register")
        ZenRetail.zenNIO.setFilter(false, methods: [.POST], url: "/api/logout")
        
        ZenRetail.zenNIO.setFilter(false, methods: [.GET], url: "/api/ecommerce/*")
        ZenRetail.zenNIO.setFilter(false, methods: [.GET], url: "/api/devicefrom/*")
        ZenRetail.zenNIO.setFilter(false, methods: [.GET], url: "/api/causalfrom/*")
        ZenRetail.zenNIO.setFilter(false, methods: [.GET], url: "/api/registryfrom/*")
        ZenRetail.zenNIO.setFilter(false, methods: [.GET], url: "/api/productfrom/*")
        ZenRetail.zenNIO.setFilter(false, methods: [.GET], url: "/api/movementfrom/*")
        ZenRetail.zenNIO.setFilter(false, methods: [.POST], url: "/api/movement")
    }
    
    private func loadConfiguration() -> Configuration {
        let fileUrl = URL(fileURLWithPath: "\(FileManager.default.currentDirectoryPath)/zenretail.json")
        print("Config: " + fileUrl.absoluteString)
        do {
            let data = try Data(contentsOf: fileUrl, options: .alwaysMapped)
            return try JSONDecoder().decode(Configuration.self, from: data)
        } catch {
            print("Config: \(error)")
            let p = Configuration()
            do {
                let str = try JSONEncoder().encode(p)
                try str.write(to: fileUrl, options: Data.WritingOptions.atomic)
            } catch {
                print("Config: \(error)")
            }
            return p
        }
    }
    
    private func saveConfiguration(cfg: Configuration) {
        let fileUrl = URL(fileURLWithPath: "\(FileManager.default.currentDirectoryPath)/zenretail.json")
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let str = try encoder.encode(ZenRetail.config)
            try str.write(to: fileUrl, options: Data.WritingOptions.atomic)
        } catch {
            print(error)
        }
    }
}
