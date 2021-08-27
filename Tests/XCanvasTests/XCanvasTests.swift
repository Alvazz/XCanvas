import XCTest
@testable import XCanvas

extension CanvasObject.Identifier {
    static let line = CanvasObject.Identifier("line")
}

class LineObject: CanvasObject {
    
    var line: Line? {
        guard let points = first, points.count == 2 else { return nil }
        return Line(from: points[0], to: points[1])
    }
    
    override var drawingStrategy: CanvasObject.DrawingStrategy {
        .default { self.first?.count != 2 ? .push : .finish }
    }
    
    override func createLayoutBrushes() -> [Brush] { [] }
    
    override func selectTest(_ rect: CGRect) -> Bool {
        guard let line = line else { return false }
        return rect.canSelect(line)
    }
    
}

enum CanvasConverter: CanvasObjectTypeConvertible {
    case line
    
    init?(identifier: CanvasObject.Identifier) {
        self = .line
    }
    
    var objectType: CanvasObject.Type {
        LineObject.self
    }
    
    
}

final class XCanvasTests: XCTestCase {
    
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

    func testCanvasObjectCodable() {
        let lineObject = LineObject()
        lineObject.push(point: .zero)
        lineObject.push(point: CGPoint(x: 100, y: 100))
        lineObject.markAsFinished()
        
        let json = try? JSONEncoder().encode(lineObject)
        XCTAssertNotNil(json)
        
        let decoded = try? JSONDecoder().decode(LineObject.self, from: json!)
        XCTAssertNotNil(json)
        
        XCTAssertNotNil(decoded?.convert(to: LineObject.self))
    }
    
    static var allTests = [
        ("testLayout", testLayout),
    ]
    
}
