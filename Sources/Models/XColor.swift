//
//  XColor.swift
//  
//
//  Created by scchn on 2021/5/5.
//

import Cocoa

public struct XColor: Codable {
    public var r, g, b, a: CGFloat
    
    public var nsColor: NSColor {
        .init(red: r, green: g, blue: b, alpha: a)
    }
}

extension NSColor {
    public var xColor: XColor {
        guard let color = usingColorSpace(.deviceRGB) else { return .init(r: 0, g: 0, b: 0, a: 1) }
        return .init(r: color.redComponent, g: color.greenComponent, b: color.blueComponent, a: color.alphaComponent)
    }
}
