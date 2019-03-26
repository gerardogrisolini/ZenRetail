import XCTest
import NIOPostgres
@testable import NIOPostgres
import ZenPostgres


final class ZenPostgresTests: XCTestCase {
    private let config = PostgresConfig(
        host: "localhost",
        port: 5432,
        tls: false,
        username: "gerardo",
        password: "grd@321.",
        database: "webretail"
    )
    private var group: EventLoopGroup!
    private var database: ZenPostgres!
    
    override func setUp() {
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        do {
            self.database = try ZenPostgres(config: config, group: group)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    override func tearDown() {
        XCTAssertNoThrow(try self.group.syncShutdownGracefully())
        self.group = nil
    }

    
    func testOpenCloseConnection() {
        do {
            let db = try database.connect()
            try db.disconnect()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testCreateTables() {
        XCTAssertNoThrow(try Organization().create())
        XCTAssertNoThrow(try Account().create())
    }

    func testInsert() {
        let organization = Organization()
        organization.organizationName = "Organization \(Date())"
        let store = Store()
        store.storeId = 1
        store.storeName = "Store 1"
        organization.organizationStore = store
        
        do {
            try organization.save { id in
                organization.organizationId = id as! Int
            }
            XCTAssertTrue(organization.organizationId > 0)
            
            let account = Account()
            account.organizationId = organization.organizationId
            account.accountName = "Gerardo Grisolini"
            account.accountEmail = "gerardo@grisolini.com"
            XCTAssertNoThrow(try account.save())
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUpdate() {
        let organization = Organization()
        organization.organizationId = 1
        organization.organizationName = "Organization \(Date())"
        let store = Store()
        store.storeId = 1
        store.storeName = "Store 2"
        organization.organizationStore = store
        XCTAssertNoThrow(try organization.save())
    }

    func testSelect() {
        let organization = Organization()
        XCTAssertNoThrow(try organization.get(1))
        XCTAssertTrue(!organization.organizationName.isEmpty)
    }
    
    func testDelete() {
        let organization = Organization()
        organization.organizationId = 1
        XCTAssertNoThrow(try organization.delete())
    }

    func testQuerySelect() {
        do {
            let rows: [Organization] = try Organization().query(
                whereclause: "Organization.organizationId > $1",
                params: [0],
                orderby: ["organizationName"],
                cursor: Cursor(limit: 5, offset: 0),
                joins: [
                    DataSourceJoin(
                        table: "Account",
                        onCondition: "organizationId",
                        direction: .INNER)
                ]
            )
            XCTAssertTrue(rows.count > 1)
            for row in rows {
                print(row.organizationStore.storeName)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testQueryUpdate() {
        do {
            let count = try Account().update(
                cols: ["accountEmail"],
                params: ["gg@grisolini.com"],
                id: "accountName",
                value: "Gerardo Grisolini"
            )
            XCTAssertTrue(count == 1)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testQueryDelete() {
        do {
            let count = try Account().delete(
                id: "accountEmail",
                value: "gg@grisolini.com"
            )
            XCTAssertTrue(count == 1)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    
    static var allTests = [
        ("testOpenCloseConnection", testOpenCloseConnection),
        ("testCreateTables", testCreateTables),
        ("testInsert", testInsert),
        ("testSelect", testSelect),
        ("testUpdate", testUpdate),
        ("testDelete", testDelete),
        ("testQuerySelect", testQuerySelect),
        ("testQueryUpdate", testQueryUpdate),
        ("testQueryDelete", testQueryDelete),
    ]

    class Store: PostgresJson {
        public var storeId: Int = 0
        public var storeName: String = ""
        
        public var json: String {
            let json = try! JSONEncoder().encode(self)
            return String(data: json, encoding: .utf8)!
        }
    }
    
    class Organization: PostgresTable, Codable {
        public var organizationId: Int = 0
        public var organizationName: String = ""
        public var organizationStore: Store = Store()
        public var _account: Account = Account()
        
        enum CodingKeys: String, CodingKey {
            case organizationId = "organizationId"
            case organizationName = "organizationName"
            case organizationStore = "organizationStore"
        }
        
        required init() {
            super.init()
        }
        
        init(from decoder: Decoder) throws {
            super.init()
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            organizationId = try container.decode(Int.self, forKey: .organizationId)
            organizationName = try container.decode(String.self, forKey: .organizationName)
            organizationStore = try container.decode(Store.self, forKey: .organizationStore)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(organizationId, forKey: .organizationId)
            try container.encode(organizationName, forKey: .organizationName)
            try container.encode(organizationStore, forKey: .organizationStore)
        }
        
        override func decode(row: PostgresRow) {
            organizationId = row.column("organizationId")?.int ?? organizationId
            organizationName = row.column("organizationName")?.string ?? organizationName
            if let store = row.column("organizationStore")?.data {
                organizationStore = try! JSONDecoder().decode(Store.self, from:store)
            }
            _account.decode(row: row)
        }
    }
    
    class Account: PostgresTable, Codable {
        public var accountId: Int = 0
        public var organizationId: Int = 0
        public var accountName: String = ""
        public var accountEmail: String = ""
        
        required init() {
            super.init()
            self.tableIndexes.append("accountEmail")
        }
        
        override func decode(row: PostgresRow) {
            accountId = row.column("accountId")?.int ?? accountId
            organizationId = row.column("organizationId")?.int ?? organizationId
            accountName = row.column("accountName")?.string ?? accountName
            accountEmail = row.column("accountEmail")?.string ?? accountEmail
        }
    }
}
