import XCTest
import ZenNIO
@testable import ZenPostgres
@testable import ZenRetailCore

final class ZenRetailTests: XCTestCase {

    private let config = PostgresConfig(
        host: "localhost",
        port: 5432,
        tls: false,
        username: "gerardo",
        password: "grd@321.",
        database: "webretail"
    )

    override func setUp() {
    }
    
    override func tearDown() {
    }

    func testQueryCategory() {
        do {
            let p = try ZenPostgres(config: config)
//            let attributeValue = AttributeValue()
//            try attributeValue.get("attributeId\" = '1' AND \"attributeValueName", 1)
//            XCTAssertTrue(attributeValue.attributeId == 1)

            let db = try p.connectAsync()
            defer { db.disconnect() }
            
            let c = Category(db: db)
            for _ in 0...100 {
                let rows = try c.query(orderby: ["categoryId"])
                XCTAssertTrue(rows.count > 0)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testQuery() {
        do {
            let p = try ZenPostgres(config: config)

            let category = DataSourceJoin(
                table: "ProductCategory",
                onCondition: "Category.categoryId = ProductCategory.categoryId",
                direction: .INNER
            )
            let product = DataSourceJoin(
                table: "Product",
                onCondition: "ProductCategory.productId = Product.productId",
                direction: .INNER
            )
            let publication = DataSourceJoin(
                table: "Publication",
                onCondition: "Product.productId = Publication.productId",
                direction: .INNER
            )

            let db = try p.connectAsync()
            defer { db.disconnect() }
            
            let c = Category(db: db)
            XCTAssertNoThrow(
                try c.query(
                    columns: ["DISTINCT Category.*"],
                    whereclause: "Publication.publicationStartAt <= $1 AND Publication.publicationFinishAt >= $1 AND Category.categoryIsPrimary = $2 AND Product.productIsActive = $2",
                    params: [Int.now(), true],
                    orderby: ["Category.categoryName"],
                    joins:  [category, product, publication]
                )
            )
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testPhantomjs() {
        let doc = PdfDocument()
        doc.content = "<html><body><h1>Hello world!!</h1></body></html>"
        doc.subject = "Test_1.png"
        
        let pdf = Utils.htmlToPdf(model: doc)
        XCTAssertNotNil(pdf)
    }
    

    static var allTests = [
        ("testQueryCategory", testQueryCategory),
        ("testQuery", testQuery),
        ("testPhantomjs", testPhantomjs),
    ]
}
