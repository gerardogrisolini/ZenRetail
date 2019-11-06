import XCTest
import ZenNIO
@testable import ZenRetailCore

final class ZenRetailTests: XCTestCase {
    
    var zenRetail = ZenRetail()
    
    override func setUp() {
        XCTAssertNoThrow(try zenRetail.setupDatabase())
    }
    
    override func tearDown() {
    }

    func testPhantomjs() {
        let doc = PdfDocument()
        doc.content = "<html><body><h1>Hello world!!</h1></body></html>"
        doc.subject = "Test_1.png"
        
        let pdf = Utils.htmlToPdf(model: doc)
        XCTAssertNotNil(pdf)
    }
    
    func testGetProduct() {
        EcommerceRepository().getProduct(name: "gaia").whenComplete { res in
            switch res {
            case .success(_):
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
        }
    }
    

    static var allTests = [
        ("testPhantomjs", testPhantomjs),
        ("testGetProduct", testGetProduct),
    ]
}
