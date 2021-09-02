//
//  CanvasObjectPasteboard.swift
//  
//
//  Created by scchn on 2021/9/2.
//

import Cocoa

extension NSPasteboard.PasteboardType {
    static let canvasObjects = NSPasteboard.PasteboardType("com.scchn.XCanvas.canvasObjects")
}

public class CanvasObjectPasteboard<T: CanvasObjectTypeConvertible>: NSObject, NSPasteboardReading, NSPasteboardWriting {
    
    public static func getInstance(from pasteboard: NSPasteboard) -> Self? {
        pasteboard.readObjects(forClasses: [Self.self])?.first as? Self
    }
    
    public static func canRead(from pasteboard: NSPasteboard) -> Bool {
        pasteboard.canReadObject(forClasses: [Self.self])
    }
    
    public let objects: [CanvasObject]
    
    public required convenience init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        guard let data = propertyList as? Data else { return nil }
        
        do {
            let objects = try PropertyListDecoder()
                .decode([CanvasObject].self, from: data)
                .map { try T.convert(object: $0).get() }
            
            self.init(objects: objects)
        } catch {
            return nil
        }
    }
    
    public init(objects: [CanvasObject]) {
        self.objects = objects.compactMap { $0.copy() as? CanvasObject }
        super.init()
    }
    
    @discardableResult
    public func write(to pasteboard: NSPasteboard) -> Bool {
        pasteboard.declareTypes([.canvasObjects], owner: nil)
        return pasteboard.writeObjects([self])
    }
    
    // MARK: -
    
    public static func readableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        [.canvasObjects]
    }

    public static func readingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.ReadingOptions {
        .asData
    }
    
    public func writingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.WritingOptions {
        .promised
    }

    public func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        [.canvasObjects]
    }

    public func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        guard type == .canvasObjects else { return nil }
        return try? PropertyListEncoder().encode(objects)
    }
    
}
