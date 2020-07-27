import XCTest

import testingTests

var tests = [XCTestCaseEntry]()
tests += testingTests.allTests()
XCTMain(tests)
