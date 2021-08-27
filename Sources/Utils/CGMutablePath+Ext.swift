//
//  CGMutablePath+Ext.swift
//  XCanvas
//
//  Created by chen on 2021/4/25.
//

import Foundation

extension CGMutablePath {
    
    public func addCircle(center: CGPoint, radius: CGFloat) {
        move(to: center.extended(length: radius, angle: 0))
        addArc(center: center, radius: radius,
               startAngle: 0, endAngle: .pi*2,
               clockwise: false)
    }
    
    public func addCircle(_ circle: Circle) {
        addCircle(center: circle.center, radius: circle.radius)
    }
    
    public func addLine(_ line: Line) {
        addLines(between: [line.from, line.to])
    }
    
    public func addArc(_ arc: Arc) {
        addArc(center: arc.center, radius: arc.radius,
               startAngle: arc.startAngle, endAngle: arc.endAngle,
               clockwise: arc.clockwise)
    }
    
    public func addArrow(at point: CGPoint, width: CGFloat, rotation: CGFloat) {
        let len = width / 2 * sqrt(2)
        let p1 = point.extended(length: len, angle: rotation)
        let p2 = point.extended(length: len, angle: rotation + .pi * 1.5)
        let p3 = point.extended(length: len, angle: rotation - .pi * 1.5)
        addLines(between: [p1, p2, p3])
        closeSubpath()
    }
    
}

