//
//  ZenRetail.swift
//  ZenRetail
//
//  Created by Gerardo Grisolini on 23/03/2019.
//

import Foundation
import NIO
import NIOHTTP1
import ZenNIO
import ZenNIOSSL
import ZenPostgres
import ZenSMTP
import Logging

public class ZenRetail {
    static var config: Configuration!
    static var zenNIO: ZenNIO!
    
    public init() {
        setup()
    }

    deinit {
        stop()
    }

    public func start() throws {
        let zenNIO = ZenNIO(host: "0.0.0.0", port: ZenRetail.config.serverPort, logs: [.console, .file])

        var logger = Logger(label: "ZenRetail")
        logger.logLevel = ZenRetail.config.logLevel
        zenNIO.logger = logger
        
        zenNIO.addCORS()
        zenNIO.addDocs(ZenRetail.config.documentRoot)
        zenNIO.addAuthentication(handler: { (username, password) -> EventLoopFuture<String> in
            let user = User()
            return user.get(usr: username, pwd: password).map { () -> String in
                return user.uniqueID
            }.flatMapError { error -> EventLoopFuture<String> in
                let registry = Registry()
                return registry.get(email: username, pwd: password).map { () -> String in
                    return registry.uniqueID
                }
            }
        })
        
        ZenRetail.zenNIO = zenNIO
        
        try setupDatabase()
        try createTables()
        try createFolders()
        try setupSmtp()

        addIoC()
        routesAndHandlers()
        addFilters()
        addErrorHandler()
        
        if ZenRetail.config.sslCert.isEmpty {
            try zenNIO.start()
        } else {
            try zenNIO.startSecure(
                certFile: ZenRetail.config.sslCert,
                keyFile: ZenRetail.config.sslKey,
                http: ZenRetail.config.httpVersion == 1 ? .v1 : .v2
            )
        }
    }
    
    public func stop() {
        ZenPostgres.pool.close()
        ZenRetail.zenNIO.stop()
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
        _ = try company.select().wait()

        if let smtpUsername = ProcessInfo.processInfo.environment["SENDGRID_USERNAME"],
            let smtpPassword = ProcessInfo.processInfo.environment["SENDGRID_PASSWORD"] {
            
            if company.smtpHost != "smtp.sendgrid.net"
                || smtpUsername != company.smtpUsername
                || smtpPassword != company.smtpPassword {
                company.smtpHost = "smtp.sendgrid.net"
                company.smtpUsername = smtpUsername
                company.smtpPassword = smtpPassword
                try company.save().wait()
            }
        }

        let config = ServerConfiguration(
            hostname: company.smtpHost,
            port: company.smtpSsl ? 587 : 25,
            username: company.smtpUsername,
            password: company.smtpPassword,
            cert: nil,
            key: nil,
            logger: ZenIoC.shared.resolve() as Logger
        )
        
        ZenSMTP.mail.setup(config: config, eventLoopGroup: ZenRetail.zenNIO.eventLoopGroup)
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
            maximumConnections: ZenRetail.config.postgresMaxConn,
            logger: ZenIoC.shared.resolve() as Logger
        )

        ZenPostgres.pool.setup(config: config, eventLoopGroup: ZenRetail.zenNIO.eventLoopGroup)
    }
 
    private func createTables() throws {
        let connection = try ZenPostgres.pool.connect().wait()
        defer { connection.disconnect() }

        let settings = Settings(connection: connection)
        try settings.create().wait()
        let company = Company()
        try company.create(connection: connection)
        let file = File(connection: connection)
        try file.create().wait()
        let user = User(connection: connection)
        try user.create().wait()
        let causal = Causal(connection: connection)
        try causal.create().wait()
        let store = Store(connection: connection)
        try store.create().wait()
        let brand = Brand(connection: connection)
        try brand.create().wait()
        let category = Category(connection: connection)
        try category.create().wait()
        let attribute = Attribute(connection: connection)
        try attribute.create().wait()
        let attributeValue = AttributeValue(connection: connection)
        try attributeValue.create().wait()
        let tagGroup = TagGroup(connection: connection)
        try tagGroup.create().wait()
        let tagValue = TagValue(connection: connection)
        try tagValue.create().wait()
        let product = Product(connection: connection)
        try product.create().wait()
        let productCategeory = ProductCategory(connection: connection)
        try productCategeory.create().wait()
        let productAttribute = ProductAttribute(connection: connection)
        try productAttribute.create().wait()
        let productAttributeValue = ProductAttributeValue(connection: connection)
        try productAttributeValue.create().wait()
        let article = Article(connection: connection)
        try article.create().wait()
        let articleAttributeValue = ArticleAttributeValue(connection: connection)
        try articleAttributeValue.create().wait()
        let stock = Stock(connection: connection)
        try stock.create().wait()
        let device = Device(connection: connection)
        try device.create().wait()
        let registry = Registry(connection: connection)
        try registry.create().wait()
        let invoice = Invoice(connection: connection)
        try invoice.create().wait()
        let movement = Movement(connection: connection)
        try movement.create().wait()
        let movementArticle = MovementArticle(connection: connection)
        try movementArticle.create().wait()
        let publication = Publication(connection: connection)
        try publication.create().wait()
        let basket = Basket(connection: connection)
        try basket.create().wait()
        let amazon = Amazon()
        try amazon.create(connection: connection).wait()
        let mwsRequest = MwsRequest(connection: connection)
        try mwsRequest.create().wait()
        
        try user.setAdmin().wait()
        try attribute.setupMarketplace().wait()
        try tagGroup.setupMarketplace().wait()
        try causal.setupDefaults()
        try file.setupShippingCost()
        //try file.importStaticFiles()
        //try category.setupMarketplace().wait()
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
        let router = ZenIoC.shared.resolve() as Router
        
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
//        _ = AmazonController(router: router)
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
        let paths = ["media", "thumb"]
        for path in paths {
            var isDirectory: ObjCBool = true
            let p = "\(ZenNIO.htdocsPath)/\(path)"
            if !fileManager.fileExists(atPath: p, isDirectory: &isDirectory) {
                try fileManager.createDirectory(atPath: p, withIntermediateDirectories: true, attributes: nil)
            }
        }
    }

    private func getFile(ctx: ChannelHandlerContext, fileName: String, size: MediaType) -> EventLoopFuture<HttpResponse> {
        let promise = ctx.eventLoop.makePromise(of: File.self)

        File().getFileAsync(filename: fileName, size: size).whenComplete { result in
           switch result {
           case .success(let file):
                promise.succeed(file)

                ctx.eventLoop.scheduleTask(in: .seconds(3), { () -> Void in
                    print("Local saving file \(size)/\(file.fileName) - \(file.fileSize / 1024)Kb")
                    let path = "\(ZenRetail.config.documentRoot)/\(size)/\(fileName)"
                    let url = URL(fileURLWithPath: path)
                    try? Data(file.fileData).write(to: url)
                })

           case .failure(let err):
                promise.fail(err)
           }
        }

        return promise.futureResult.map { f -> HttpResponse in
           let response = HttpResponse(body: ctx.channel.allocator.buffer(capacity: f.fileSize))
           response.addHeader(.contentType, value: f.fileContentType)
           //response.body.reserveCapacity(f.fileSize)
           response.body.writeBytes(f.fileData)
           response.success()
           return response
        }
    }
    
    private func addErrorHandler() {
        ZenRetail.zenNIO.addError { (ctx, request, error) -> EventLoopFuture<HttpResponse> in
            let log = Logger.Message(stringLiteral: "⚠️ \(request.method) \(request.uri) || \(error)")
            (ZenIoC.shared.resolve() as Logger).error(log)
            ZenRetail.zenNIO.logger.error(log)
            
            var html = ""
            var status: HTTPResponseStatus

            func responseComplete() -> EventLoopFuture<HttpResponse> {
                html = """
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html>
<head><title>ZenRetail</title></head>
<body>
    <h1>ZenRetail</h1>
    <h3>\(status.code) - \(status.reasonPhrase)</h3>
    <h4>\(html)</h4>
</body>
</html>
"""
                let response = HttpResponse(body: ctx.channel.allocator.buffer(capacity: 0))
                response.send(html: html)
                response.success(status)
                return ctx.eventLoop.future(response)
            }
            
            switch error {
            case let e as IOError where e.errnoCode == ENOENT:
                status = .notFound

                // syncronize from database
                if request.uri.hasPrefix("/thumb/") || request.uri.hasPrefix("/media/") {
                    let size: MediaType = request.uri.hasPrefix("/thumb/") ? .thumb : .media
                    let fileName = request.uri.dropFirst(7).description
                    return self.getFile(ctx: ctx, fileName: fileName, size: size).map { response -> HttpResponse in
                        return response
                    }.flatMapError { error -> EventLoopFuture<HttpResponse> in
                        return responseComplete()
                    }
                }

            case let e as IOError:
                html = e.localizedDescription
                status = .expectationFailed
            case let e as HttpError:
                switch e {
                case .unauthorized:
                    status = .unauthorized
                case .notFound:
                    status = .notFound
                case .badRequest(let reason):
                    status = .badRequest
                    html = reason
                case .internalError(let reason):
                    status = .internalServerError
                    html = reason
                case .custom(let code, let reason):
                    status = .custom(code: code, reasonPhrase: reason)
                }
            default:
                html = error.localizedDescription
                status = .internalServerError
            }
            
            return responseComplete()
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
