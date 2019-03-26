import XCTest

import ZenPostgreSQLTests

var tests = [XCTestCaseEntry]()
tests += ZenPostgreSQLTests.allTests()
XCTMain(tests)
