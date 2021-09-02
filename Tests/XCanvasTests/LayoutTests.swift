import XCTest
@testable import XCanvas

final class LayoutTests: XCTestCase {
    
    func testLayout() {
        let data = [
            [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 2, y: 0)],
            [CGPoint(x: 0, y: 1), CGPoint(x: 1, y: 1), CGPoint(x: 2, y: 1)],
            [CGPoint(x: 0, y: 2), CGPoint(x: 1, y: 2)],
        ]
        var layout = Layout(data)
        
        for (index, points) in layout.enumerated() {
            XCTAssertEqual(points, data[index])
        }
        
        XCTAssertNotNil(layout.first?.first)
        XCTAssertEqual(layout.first?.first, data.first?.first)
        
        // Pop
        XCTAssertEqual(layout.pop(), data.last?.last)
        
        // Push
        let last = CGPoint(x: 2, y: 2)
        layout.push(last)
        XCTAssertEqual(layout.last?.last, last)
    }
    
    static var allTests = [
        ("testLayout", testLayout),
    ]
    
}
