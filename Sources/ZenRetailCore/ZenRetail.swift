//
//  ZenRetail.swift
//  ZenRetail
//
//  Created by Gerardo Grisolini on 23/03/2019.
//

import Foundation
import ZenNIO
import ZenSMTP
import ZenPostgres


public class ZenRetail {
    var configuration: Configuration!
    static var zenNIO: ZenNIO!
    var zenPostgres: ZenPostgres!
    var zenSMTP: ZenSMTP!
    let router = Router()

    public init() throws {
        try setup()
    }

    deinit {
        stop()
    }

    public func start() throws {
        ZenRetail.zenNIO = ZenNIO(host: configuration.serverName, port: configuration.serverPort, router: router)
        ZenRetail.zenNIO.addCORS()
        ZenRetail.zenNIO.addWebroot(path: configuration.documentRoot)
        ZenRetail.zenNIO.addAuthentication(handler: { (email, password) -> (Bool) in
            return email == password
        })
        
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

    private func setup() throws {
        configuration = loadConfiguration()
        
        if let serverName = ProcessInfo.processInfo.environment["HOST"] {
            configuration.serverName = serverName
        }
        if let portString = ProcessInfo.processInfo.environment["PORT"] {
            configuration.serverPort = Int(portString)!
        }
        if let databaseUrl = ProcessInfo.processInfo.environment["DATABASE_URL"] {
            parseConnectionString(databaseUrl: databaseUrl)
        }
        try setupDatabase()
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
        configuration.postgresUsername = url[url.startIndex...index].description
        
        index = url.index(index, offsetBy: 2)
        var index2 = url.index(before: url.firstIndex(of: "@")!)
        configuration.postgresPassword = url[index...index2].description
        
        index = url.index(index2, offsetBy: 2)
        url = url[index...].description
        
        index2 = url.index(before: url.firstIndex(of: ":")!)
        configuration.postgresHost = url[url.startIndex...index2].description
        
        index = url.index(index2, offsetBy: 2)
        index2 = url.index(before: url.firstIndex(of: "/")!)
        configuration.postgresPort = Int(url[index...index2].description)!
        
        index = url.index(index2, offsetBy: 2)
        configuration.postgresDatabase = url[index...].description
    }
    
    private func setupDatabase() throws {
        
        let config = PostgresConfig(
            host: configuration.postgresHost,
            port: configuration.postgresPort,
            tls: false,
            username: configuration.postgresUsername,
            password: configuration.postgresPassword,
            database: configuration.postgresDatabase
        )
        zenPostgres = try ZenPostgres(config: config)
    }
 
    private func createTables() throws {
        let db = try ZenPostgres.shared.connect()
        
        let company = Company()
        try company.create(db: db)
        let settings = Settings(db: db)
        try settings.create()
        let file = File(db: db)
        try file.create()
        try file.setupShippingCost()
        let ats = AccessTokenStore(db: db)
        try ats.create()
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
        try category.setupMarketplace()
        let attribute = Attribute(db: db)
        try attribute.create()
        let attributeValue = AttributeValue(db: db)
        try attributeValue.create()
        try attribute.setupMarketplace()
        let tagGroup = TagGroup(db: db)
        try tagGroup.create()
        let tagValue = TagValue(db: db)
        try tagValue.create()
        try tagGroup.setupMarketplace()
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
        
        db.disconnect()
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
        ZenRetail.zenNIO.setFilter(false, methods: [.POST], url: "/api/logout")
        ZenRetail.zenNIO.setFilter(false, methods: [.GET], url: "/api/ecommerce/*")
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
            let str = try JSONEncoder().encode(configuration)
            try str.write(to: fileUrl, options: Data.WritingOptions.atomic)
        } catch {
            print(error)
        }
    }

    static func angularHandler(webapi: Bool = true) -> HttpHandler {
        return { req, resp in
            resp.addHeader(.location, value: webapi ? "/admin/index.html" : "/web/index.html")
//            let data = FileManager.default.contents(atPath: webapi ? "./webroot/admin/index.html" : "./webroot/web/index.html")
//            guard let content = data else {
//                resp.completed( .notFound)
//                return
//            }
//
//            resp.send(html: String(data: content, encoding: .utf8)!)
            resp.completed(.found)
        }
    }
}
