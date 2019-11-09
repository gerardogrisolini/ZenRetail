//
//  ZenRetail.swift
//  ZenRetail
//
//  Created by Gerardo Grisolini on 23/03/2019.
//

import Foundation
import NIOHTTP1
import ZenNIO
import ZenNIOSSL
import ZenSMTP
import ZenPostgres
import PostgresNIO


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
        try createFolders()
        try setupSmtp()
        
        addIoC()
        routesAndHandlers()
        addFilters()
        addErrorHandler()
        
        if ZenRetail.config.sslCert.isEmpty {
            try ZenRetail.zenNIO.start()
        } else {
            try ZenRetail.zenNIO.startSecure(
                certFile: ZenRetail.config.sslCert,
                keyFile: ZenRetail.config.sslKey,
                http: ZenRetail.config.httpVersion == 1 ? .v1 : .v2
            )
        }
    }

    public func stop() {
        try? zenSMTP?.close()
    }
    
    private func setup() {
        ZenRetail.config = loadConfiguration()
        
        if let host = ProcessInfo.processInfo.environment["HOST"] {
            ZenRetail.config.serverHost = host
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

        if let smtpUsername = ProcessInfo.processInfo.environment["SENDGRID_USERNAME"],
            let smtpPassword = ProcessInfo.processInfo.environment["SENDGRID_PASSWORD"] {
            
            if company.smtpHost != "smtp.sendgrid.net"
                || smtpUsername != company.smtpUsername
                || smtpPassword != company.smtpPassword {
                company.smtpHost = "smtp.sendgrid.net"
                company.smtpUsername = smtpUsername
                company.smtpPassword = smtpPassword
                try company.save()
            }
        }

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
        let config = PostgresConfig(
            host: ZenRetail.config.postgresHost,
            port: ZenRetail.config.postgresPort,
            tls: ZenRetail.config.postgresTsl,
            username: ZenRetail.config.postgresUsername,
            password: ZenRetail.config.postgresPassword,
            database: ZenRetail.config.postgresDatabase,
            maximumConnections: ZenRetail.config.postgresMaxConn
        )

        zenPostgres = try ZenPostgres(config: config)
    }
 
    private func createTables() throws {
        let connection = try ZenPostgres.pool.connect()
        defer { connection.disconnect() }

        let settings = Settings(connection: connection)
        try settings.create()
        let company = Company()
        try company.create(connection: connection)
        let file = File(connection: connection)
        try file.create()
        try file.setupShippingCost()
        //try file.importStaticFiles()
        let user = User(connection: connection)
        try user.create()
        try user.setAdmin()
        let causal = Causal(connection: connection)
        try causal.create()
        try causal.setupDefaults()
        let store = Store(connection: connection)
        try store.create()
        let brand = Brand(connection: connection)
        try brand.create()
        let category = Category(connection: connection)
        try category.create()
        //try category.setupMarketplace()
        let attribute = Attribute(connection: connection)
        try attribute.create()
        let attributeValue = AttributeValue(connection: connection)
        try attributeValue.create()
        try attribute.setupMarketplace()
        let tagGroup = TagGroup(connection: connection)
        try tagGroup.create()
        let tagValue = TagValue(connection: connection)
        try tagValue.create()
        //try tagGroup.setupMarketplace()
        let product = Product(connection: connection)
        try product.create()
        let productCategeory = ProductCategory(connection: connection)
        try productCategeory.create()
        let productAttribute = ProductAttribute(connection: connection)
        try productAttribute.create()
        let productAttributeValue = ProductAttributeValue(connection: connection)
        try productAttributeValue.create()
        let article = Article(connection: connection)
        try article.create()
        let articleAttributeValue = ArticleAttributeValue(connection: connection)
        try articleAttributeValue.create()
        let stock = Stock(connection: connection)
        try stock.create()
        let device = Device(connection: connection)
        try device.create()
        let registry = Registry(connection: connection)
        try registry.create()
        let invoice = Invoice(connection: connection)
        try invoice.create()
        let movement = Movement(connection: connection)
        try movement.create()
        let movementArticle = MovementArticle(connection: connection)
        try movementArticle.create()
        let publication = Publication(connection: connection)
        try publication.create()
        let basket = Basket(connection: connection)
        try basket.create()
        let amazon = Amazon()
        try amazon.create(connection: connection)
        let mwsRequest = MwsRequest(connection: connection)
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
    
    private func createFolders() throws {
        let fileManager = FileManager.default
        let paths = ["csv", "media", "thumb"]
        for path in paths {
            var isDirectory: ObjCBool = true
            let p = "\(ZenNIO.htdocsPath)/\(path)"
            if !fileManager.fileExists(atPath: p, isDirectory: &isDirectory) {
                try fileManager.createDirectory(atPath: p, withIntermediateDirectories: true, attributes: nil)
            }
        }
    }

    private func getFile(response: HttpResponse, fileName: String, size: MediaType) {
        let file = File()
        if let data = try? file.getData(filename: fileName, size: size) {
                response.addHeader(.contentType, value: file.fileContentType)
                response.body.reserveCapacity(data.count)
                response.body.writeBytes(data)
                response.completed()
            
            ZenRetail.zenNIO.eventLoopGroup.next().execute {
                let path = "\(ZenRetail.config.documentRoot)/\(size)/\(fileName)"
                let url = URL(fileURLWithPath: path)
                try? Data(data).write(to: url)
            }
        } else {
            response.completed( .notFound)
        }
    }
    
    private func addErrorHandler() {
        ZenRetail.zenNIO.addError { (ctx, request, error) -> HttpResponse in
            let response = HttpResponse(body: ctx.channel.allocator.buffer(capacity: 0))

            var html = ""
            var status: HTTPResponseStatus
            switch error {
            case let e as IOError where e.errnoCode == ENOENT:
                html += "<h3>IOError (not found)</h3>"
                status = .notFound
      
                // syncronize from database
                switch request.uri {
                case let str where str.contains("/thumb/"):
                    let fileName = request.uri.replacingOccurrences(of: "/thumb/", with: "")
                    self.getFile(response: response, fileName: fileName, size: .thumb)
                    return response
                case let str where str.contains("/media/"):
                    let fileName = request.uri.replacingOccurrences(of: "/media/", with: "")
                    self.getFile(response: response, fileName: fileName, size: .media)
                    return response
                case let str where str.contains("/csv/"):
                    let fileName = request.uri.replacingOccurrences(of: "/csv/", with: "")
                    self.getFile(response: response, fileName: fileName, size: .csv)
                    return response
                default:
                    break
                }
            case let e as IOError:
                html += "<h3>IOError (other)</h3><h4>\(e.description)</h4>"
                status = .expectationFailed
            default:
                html += "<h3>\(type(of: error)) error</h3>"
                status = .internalServerError
            }
            
            html = """
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html>
<head><title>ZenRetail</title></head>
<body>
    <h1>ZenRetail</h1>
    \(html)
</body>
</html>
"""
            response.send(html: html)
            response.completed(status)
            return response
        }
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
