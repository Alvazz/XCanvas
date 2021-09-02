//
//  CGPathDescriptor.swift
//  XCanvas
//
//  Created by chen on 2021/4/24.
//

import Cocoa

extension CGPathDescriptor {
    
    public enum Method: Equatable {
        /**
         Stroke Path
         
         1. Line width
        */
        case stroke(CGFloat)
        
        /**
         Dashed Path
         
         1. Line Width
         2. Phase
         3. Lengths
         */
        case dash(CGFloat, CGFloat, [CGFloat])
        
        // Fill Path
        case fill
        
        public static func defaultDash(width: CGFloat) -> Method { .dash(width, 0, [4]) }
        
    }
    
    public class Shadow {
        public var offset: CGSize
        public var blur: CGFloat
        public var color: NSColor?
        
        init(offset: CGSize, blur: CGFloat, color: NSColor? = nil) {
            self.offset = offset
            self.blur = blur
            self.color = color
        }
    }
    
}

public class CGPathDescriptor: CGPathProvider {
    
    public var method: Method
    public var color: NSColor
    public var cgPath: CGPath
    public var lineCap: CGLineCap = .butt
    public var lineJoin: CGLineJoin = .miter
    public var miterLimit: CGFloat = 10
    public var shadow: Shadow?
    
    public init(method: Method, color: NSColor, path: CGPath) {
        self.method = method
        self.color = color
        self.cgPath = path
    }
    
    public init(method: Method, color: NSColor, _ make: (CGMutablePath) -> Void) {
        let path = CGMutablePath()
        self.method = method
        self.color = color
        self.cgPath = path
        make(path)
    }
    
    public func draw(in ctx: CGContext) {
        defer { ctx.restoreGState() }
        ctx.saveGState()
        
        if let shadow = shadow {
            ctx.setShadow(offset: shadow.offset, blur: shadow.blur, color: shadow.color?.cgColor)
        }
        
        ctx.addPath(cgPath)
        
        switch method {
        case .dash(let w, let p, let ls):
            ctx.setLineDash(phase: p, lengths: ls); fallthrough
        case .stroke(let w):
            ctx.setLineCap(lineCap)
            ctx.setLineJoin(lineJoin)
            ctx.setMiterLimit(10)
            ctx.setLineWidth(w)
            ctx.setStrokeColor(color.cgColor)
            ctx.strokePath()
        default:
            ctx.setFillColor(color.cgColor)
            ctx.fillPath()
        }
    }
    
    public func contains(point: CGPoint, range: CGFloat) -> Bool {
        switch method {
        case .dash(let w, _, _): fallthrough
        case .stroke(let w):
            let path = cgPath.copy(
                strokingWithWidth: w + range * 2,
                lineCap: .butt,
                lineJoin: .miter,
                miterLimit: 10
            )
            
            return path.contains(point)
        case .fill:
            return cgPath.contains(point, using: .evenOdd)
        }
    }
    
}
