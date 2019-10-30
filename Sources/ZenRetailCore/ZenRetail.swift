//
//  ZenRetail.swift
//  ZenRetail
//
//  Created by Gerardo Grisolini on 23/03/2019.
//

import Foundation
import ZenNIO
import ZenNIOSSL
import ZenSMTP
import ZenPostgres
import PostgresClientKit


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
        ZenRetail.zenNIO = ZenNIO(host: "0.0.0.0", port: ZenRetail.config.serverPort, router: router)
        if !ZenRetail.config.sslCert.isEmpty {
            try ZenRetail.zenNIO.addSSL(
                certFile: ZenRetail.config.sslCert,
                keyFile: ZenRetail.config.sslKey,
                http: ZenRetail.config.httpVersion == 1 ? .v1 : .v2
            )
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
    
    public func setupDatabase() throws {
        var configuration = PostgresClientKit.ConnectionConfiguration()
        configuration.host = ZenRetail.config.postgresHost
        configuration.port = ZenRetail.config.postgresPort
        configuration.database = ZenRetail.config.postgresDatabase
        configuration.user = ZenRetail.config.postgresUsername
        configuration.ssl = false
        if !ZenRetail.config.postgresPassword.isEmpty {
            configuration.credential = .md5Password(password: ZenRetail.config.postgresPassword)
        }
        zenPostgres = try ZenPostgres(config: configuration)
    }
 
    private func createTables() throws {
        let db = try ZenPostgres.shared.connect()
        defer { db.disconnect() }

        let settings = Settings(db: db)
        try settings.create()
        let company = Company()
        try company.create(db: db)
        let file = File(db: db)
        try file.create()
        try file.setupShippingCost()
        try file.importStaticFiles()
        let user = User(db: db)
        try user.create()
        try user.setAdmin()
        let causal = Causal(db: db)
        try causal.create()
        try causal.setupDefaults()
        let store = Store(db: db)
        try store.create()
        let brand = Brand(db: db)
        try brand.create()
        let category = Category(db: db)
        try category.create()
        //try category.setupMarketplace()
        let attribute = Attribute(db: db)
        try attribute.create()
        let attributeValue = AttributeValue(db: db)
        try attributeValue.create()
        try attribute.setupMarketplace()
        let tagGroup = TagGroup(db: db)
        try tagGroup.create()
        let tagValue = TagValue(db: db)
        try tagValue.create()
        //try tagGroup.setupMarketplace()
        let product = Product(db: db)
        try product.create()
        let productCategeory = ProductCategory(db: db)
        try productCategeory.create()
        let productAttribute = ProductAttribute(db: db)
        try productAttribute.create()
        let productAttributeValue = ProductAttributeValue(db: db)
        try productAttributeValue.create()
        let article = Article(db: db)
        try article.create()
        let articleAttributeValue = ArticleAttributeValue(db: db)
        try articleAttributeValue.create()
        let stock = Stock(db: db)
        try stock.create()
        let device = Device(db: db)
        try device.create()
        let registry = Registry(db: db)
        try registry.create()
        let invoice = Invoice(db: db)
        try invoice.create()
        let movement = Movement(db: db)
        try movement.create()
        let movementArticle = MovementArticle(db: db)
        try movementArticle.create()
        let publication = Publication(db: db)
        try publication.create()
        let basket = Basket(db: db)
        try basket.create()
        let amazon = Amazon()
        try amazon.create(db: db)
        let mwsRequest = MwsRequest(db: db)
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
