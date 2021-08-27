//
//  CGPoint+Ext.swift
//  
//
//  Created by scchn on 2021/4/23.
//

import Foundation

extension CGPoint {
    
    public func extended(length: CGFloat, angle: CGFloat = 0) -> CGPoint {
        CGPoint(x: x + length * cos(angle), y: y + length * sin(angle))
    }
    
    public mutating func extend(length: CGFloat, angle: CGFloat = 0) {
        self = extended(length: length, angle: angle)
    }
    
    public func rotated(origin: CGPoint, angle: CGFloat) -> CGPoint {
        let transform = CGAffineTransform.identity.translatedBy(x: origin.x, y: origin.y).rotated(by: angle)
        return CGPoint(x: x - origin.x, y: y - origin.y).applying(transform)
    }
    
    public mutating func rotate(origin: CGPoint, angle: CGFloat) {
        self = rotated(origin: origin, angle: angle)
    }
    
    public func contains(_ point: CGPoint, in radius: CGFloat) -> Bool {
        let dx = point.x - x
        let dy = point.y - y
        return dx * dx + dy * dy <= radius * radius
    }
    
    public func mid(with point: CGPoint) -> CGPoint {
        CGPoint(x: (self.x + point.x) / 2, y: (self.y + point.y) / 2)
    }
    
    public func distance(with point: CGPoint) -> CGFloat {
        let dx = point.x - self.x
        let dy = point.y - self.y
        return sqrt(dx * dx + dy * dy)
    }
    
}

