import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(LayoutTests.allTests),
        testCase(CanvasObjectTests.allTests),
    ]
}
#endif
