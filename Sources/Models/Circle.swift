//
//  Circle.swift
//  
//
//  Created by scchn on 2021/4/23.
//

import Foundation

public struct Circle {
    
    public var center: CGPoint
    public var radius: CGFloat
    
    public init(center: CGPoint, radius: CGFloat) {
        self.center = center
        self.radius = radius
    }
    
    public init?(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) {
        guard let (center, radius) = calcCircle(p1, p2, p3) else { return nil }
        self.center = center
        self.radius = radius
    }
    
    public func contains(_ point: CGPoint) -> Bool {
        center.contains(point, in: radius)
    }
    
}
