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

    public func start() throws {
        defer { zenPostgres.close() }
        try ZenRetail.zenNIO.start()
    }

    private func setup() throws {
        configuration = loadConfiguration()
        
        if let serverName = ProcessInfo.processInfo.environment["HOST"] {
            configuration.serverName = serverName
        }
        if let portString = ProcessInfo.processInfo.environment["PORT"] {
            configuration.serverPort = Int(portString)!
        }
        let databaseUrl = ProcessInfo.processInfo.environment["DATABASE_URL"]
        
        try setupDatabase(databaseUrl: databaseUrl)
        try setupSmtp()
        
        addIoC()
        routesAndHandlers()
        addFilters()

        ZenRetail.zenNIO = ZenNIO(host: configuration.serverName, port: configuration.serverPort, router: router)
        ZenRetail.zenNIO.addCORS()
        ZenRetail.zenNIO.addWebroot(path: configuration.documentRoot)
        ZenRetail.zenNIO.addAuthentication(handler: { (email, password) -> (Bool) in
            return email == password
        })

    }
    
    private func setupSmtp() throws {
        let company = Company()
        try company.select()
        
        let config = ServerConfiguration(
            hostname: company.smtpHost,
            port: company.smtpSsl ? 546 : 25,
            username: company.smtpUsername,
            password: company.smtpPassword,
            cert: nil,
            key: nil
        )
        zenSMTP = ZenSMTP(config: config)
    }
    
    private func setupDatabase(databaseUrl: String?) throws {
        
//    if let databaseUrl = databaseUrl {
//        var url = databaseUrl.replacingOccurrences(of: "postgres://", with: "")
//        let index1 = url.firstIndex(of: ":")!
//        configuration.postgresUsername = url[url.startIndex...index1].description
//
//        let index2 = url.firstIndex(of: "@")!
//        configuration.postgresPassword = url.substring(index1 + 1, length: index2 - index1 - 1)
//        url = url.substring(index2 + 1, length: url.length - index2 - 1)
//
//        let index3 = url.firstIndex(of: ":")!
//        configuration.postgresHost = url.substring(0, length: index3)
//
//        let index4 = url.firstIndex(of: "/")!
//        configuration.postgresPort = Int(url.substring(index3 + 1, length: index4 - index3 - 1))!
//        configuration.postgresDatabase = url.substring(index4 + 1, length: url.length - index4 - 1)
//    }

        let config = PostgresConfig(
            host: configuration.postgresHost,
            port: configuration.postgresPort,
            tls: false,
            username: configuration.postgresUsername,
            password: configuration.postgresPassword,
            database: configuration.postgresDatabase
        )
        zenPostgres = try ZenPostgres(config: config)
        
        try Settings().create()
        let file = File()
        try file.create()
        try file.setupShippingCost()
        try Company().create()
        try AccessTokenStore().create()
        let user = User()
        try user.create()
        try user.setAdmin()
        let causal = Causal()
        try causal.create()
        try causal.setupDefaults()
        try Store().create()
        try Brand().create()
        let category = Category()
        try category.create()
        try category.setupMarketplace()
        let attribute = Attribute()
        try attribute.create()
        try AttributeValue().create()
        try attribute.setupMarketplace()
        let tagGroup = TagGroup()
        try tagGroup.create()
        try TagValue().create()
        try tagGroup.setupMarketplace()
        try Product().create()
        try ProductCategory().create()
        try ProductAttribute().create()
        try ProductAttributeValue().create()
        try Article().create()
        try ArticleAttributeValue().create()
        try Stock().create()
        try Device().create()
        try Registry().create()
        try Invoice().create()
        try Movement().create()
        try MovementArticle().create()
        try Publication().create()
        try Basket().create()
        try Amazon().create()
        try MwsRequest().create()
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
        ZenRetail.zenNIO.addFilter(method: .POST, url: "/api/*")
//        authenticationConfig.exclude("/api/login")
//        authenticationConfig.exclude("/api/logout")
//        authenticationConfig.exclude("/api/register")
//        authenticationConfig.exclude("/api/ecommerce/*")
//        authenticationConfig.exclude("/api/ecommerce/category/*")
//        authenticationConfig.exclude("/api/ecommerce/brand/*")
//        authenticationConfig.exclude("/api/ecommerce/product/*")
        
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
    
    private func makeSetupdHandlers(router: Router) {
        router.get("/setup", handler: setupHandlerGET)
        router.post("/setup", handler: setupHandlerPOST)
    }
    
    private let header = "<html>" +
        "<head>" +
        "<title>Webretail - PostgreSql configuration</title>" +
        "<meta charset=\"UTF-8\">" +
        "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">" +
        "<style>" +
        "body { font-family: arial; } " +
        "h3 { width: 100%; text-align: center; }" +
        ".logo { height: 100px; } " +
        "header { text-align: center; } " +
        "input { width: 100%; font-size: large; } " +
        "fieldset { margin-bottom: 20px; } " +
        "button { width: 100%; height: 50px; font-size: large; margin: 10px 0; } " +
    "</style></head><body>"
    
    private let footer = "</body></html>"
    
    private func setupHandlerPOST(request: HttpRequest, _ response: HttpResponse) {
        if let host = request.getParam(String.self, key: "host"),
            let port = request.getParam(Int.self, key: "port"),
            let name = request.getParam(String.self, key: "name"),
            let usr = request.getParam(String.self, key: "usr"),
            let pwd = request.getParam(String.self, key: "pwd") {
            
            configuration.postgresHost = host
            configuration.postgresPort = port
            configuration.postgresDatabase = name
            configuration.postgresUsername = usr
            configuration.postgresPassword = pwd
            saveConfiguration(cfg: configuration)
            
            let hml = """
            \(header)
            <h2>PostgreSql configuration: success</h2>
            <a href=\"/admin/login\">Login</a>
            \(footer)
            """
            response.send(html: hml)
            response.completed()
        } else {
            response.badRequest(error: "invalid parameters")
        }
    }
    
    private func setupHandlerGET(request: HttpRequest, _ response: HttpResponse) {
        
        let form = "<form method=\"POST\" action=\"/setup\">" +
            "<h3>PostgreSql configuration</h3>" +
            "<fieldset>" +
            "   <legend>HOST</legend>" +
            "   <input name=\"host\" type=\"text\" value=\"\(configuration.postgresHost)\" placeholder=\"Type ip address or domain\"/>" +
            "</fieldset>" +
            "<fieldset>" +
            "   <legend>PORT</legend>" +
            "   <input name=\"port\" type=\"text\" value=\"\(configuration.postgresPort)\" placeholder=\"Type port number\"/>" +
            "</fieldset>" +
            "<fieldset>" +
            "   <legend>NAME</legend>" +
            "   <input name=\"name\" type=\"text\" value=\"\(configuration.postgresDatabase)\" placeholder=\"Type database name\"/>" +
            "</fieldset>" +
            "<fieldset>" +
            "   <legend>USER</legend>" +
            "   <input name=\"usr\" type=\"text\" value=\"\(configuration.postgresUsername)\" placeholder=\"Type username\"/>" +
            "</fieldset>" +
            "<fieldset>" +
            "   <legend>PASSWORD</legend>" +
            "   <input name=\"pwd\" type=\"password\" value=\"\(configuration.postgresPassword)\" placeholder=\"Type password\"/>" +
            "</fieldset>" +
            "<button type=\"submit\" style=\"background-color: lightgreen\">Save</button>" +
        "</form>"
        
        response.send(html: header + form + footer)
        response.completed()
    }

    static func angularHandler(webapi: Bool = true) -> HttpHandler {
        return {
            req, resp in
            resp.addHeader(.contentType, value: "text/html")
            
            let data = FileManager.default.contents(atPath: webapi ? "./webroot/admin/index.html" : "./webroot/web/index.html")
            
            guard let content = data else {
                resp.completed( .notFound)
                return
            }
            
            resp.send(text: String(data: content, encoding: .utf8)!)
            resp.completed()
        }
    }
}
