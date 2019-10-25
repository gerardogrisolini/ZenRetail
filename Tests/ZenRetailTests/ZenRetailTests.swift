import XCTest
import ZenNIO
@testable import ZenRetailCore

final class ZenRetailTests: XCTestCase {

    override func setUp() {
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
    

    static var allTests = [
        ("testPhantomjs", testPhantomjs),
    ]
}
