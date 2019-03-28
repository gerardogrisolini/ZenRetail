import XCTest
@testable import ZenPostgres
@testable import ZenRetailCore

final class ZenRetailTests: XCTestCase {

    override func setUp() {
        XCTAssertNoThrow(try ZenRetail())
    }
    
    override func tearDown() {
    }

    func testQueryCategory() {
        for _ in 0...100 {
            XCTAssertNoThrow(try Category().query(orderby: ["categoryId"]))
        }
    }
    
    func testQuery() {
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
        
        XCTAssertNoThrow(try Category().query(
            columns: ["DISTINCT Category.*"],
//            whereclause: "Publication.publicationStartAt <= $1 AND Publication.publicationFinishAt >= $1 AND Category.categoryIsPrimary = $2 AND Publication.productIsActive = $2",
            params: [Int.now(), true],
            orderby: ["Category.categoryName"],
            joins:  [category, product, publication]
        ))
    }

    
    static var allTests = [
        ("testQuery", testQuery),
    ]
}
