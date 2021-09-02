import XCTest
@testable import XCanvas

final class CanvasObjectTests: XCTestCase {
    
    func testCodable() {
        let lineObject = LineObject()
        lineObject.push(point: .zero)
        lineObject.push(point: CGPoint(x: 100, y: 100))
        
        XCTAssertTrue(lineObject.markAsFinished(), "Finish failed.")
        
        let json = try? JSONEncoder().encode(lineObject)
        XCTAssertNotNil(json, "Encode failed")
        
        let object = try? JSONDecoder().decode(CanvasObject.self, from: json!)
        XCTAssertNotNil(json)
        
        let _object = try? CanvasObjectConverter.convert(object: object!).get()
        XCTAssertNotNil(_object)
        XCTAssertTrue(_object is LineObject)
    }
    
    static var allTests = [
        ("testCodable", testCodable),
    ]
    
}

// MARK: -

extension CanvasObject.Identifier {
    static let line = CanvasObject.Identifier("line")
}

class LineObject: CanvasObject {
    
    override var identifier: CanvasObject.Identifier? { .line }
    
    override var drawingStrategy: CanvasObject.DrawingStrategy {
        .default { self.first?.count != 2 ? .push : .finish }
    }
    
}

enum CanvasObjectConverter: String, CanvasObjectTypeConvertible {
    
    case line
    
    init?(identifier: CanvasObject.Identifier) {
        switch identifier.rawValue {
        case CanvasObjectConverter.line.rawValue:
            self = .line
        default:
            return nil
        }
    }
    
    var objectType: CanvasObject.Type {
        switch self {
        case .line: return LineObject.self
        }
    }
        
}
