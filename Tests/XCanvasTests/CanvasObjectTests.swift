import XCTest
@testable import XCanvas

final class CanvasObjectTests: XCTestCase {
    
    let lineObject: LineObject = {
        let lineObject = LineObject()
        lineObject.push(point: .zero)
        lineObject.push(point: CGPoint(x: 100, y: 100))
        return lineObject
    }()
    
    func testObject() {
        XCTAssertTrue(lineObject.markAsFinished(), "Finish failed.")
    }
    
    func testCodable() {
        guard let json = try? JSONEncoder().encode(lineObject) else {
            XCTFail("Encode object failed.")
            return
        }
        
        guard let decoded = try? JSONDecoder().decode(CanvasObject.self, from: json) else {
            XCTFail("Decode object failed.")
            return
        }
        
        guard let object = try? CanvasObjectConverter.convert(object: decoded).get() else {
            XCTFail("Convert object type failed.")
            return
        }
        
        XCTAssertTrue(object is LineObject)
    }
    
    func testPasteboard() {
        typealias Pasteboard = CanvasObjectPasteboard<CanvasObjectConverter>
        
        XCTAssertTrue(Pasteboard(objects: [lineObject]).write(to: .general))
        XCTAssertTrue(Pasteboard.canRead(from: .general))
        
        guard let pasteboard = Pasteboard.getInstance(from: .general) else {
            XCTFail("Get pasteboard instance failed.")
            return
        }
        
        XCTAssertEqual(pasteboard.objects.count, 1)
        XCTAssertTrue(pasteboard.objects[0] is LineObject)
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
