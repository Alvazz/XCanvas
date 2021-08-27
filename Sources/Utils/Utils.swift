//
//  Utils.swift
//  
//
//  Created by chen on 2021/5/7.
//

import Foundation

// MARK: - Common

func calcScaleFactors(from fromSize: CGSize, to toSize: CGSize) -> CGPoint {
    CGPoint(x: toSize.width / fromSize.width, y: toSize.height / fromSize.height)
}

// MARK: - Angle

public func calcAngle(_ vertex: CGPoint, _ pointA: CGPoint, _ pointB: CGPoint) -> CGFloat? {
    let len1 = vertex.distance(with: pointA)
    let len2 = vertex.distance(with: pointB)
    let len3 = pointA.distance(with: pointB)
    let a = (len1 * len1 + len2 * len2 - len3 * len3)
    let b = (len1 * len2 * 2.0)
    return b == 0 ? nil : acos(a / b)
}

// MARK: - 3-Point Circle

fileprivate func calcA(_ pointA: CGPoint, _ pointB: CGPoint, _ pointC: CGPoint) -> CGFloat {
    return (pointA.x * (pointB.y - pointC.y) - pointA.y * (pointB.x - pointC.x) + pointB.x * pointC.y - pointC.x * pointB.y)
}

fileprivate func calcB(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat{
    let a = (p1.x * p1.x + p1.y * p1.y) * (p3.y - p2.y)
    let b = (p2.x * p2.x + p2.y * p2.y) * (p1.y - p3.y)
    let c = (p3.x * p3.x + p3.y * p3.y) * (p2.y - p1.y)
    return a + b + c
}

fileprivate func calcC(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat{
    let a = (p1.x * p1.x + p1.y * p1.y) * (p2.x - p3.x)
    let b = (p2.x * p2.x + p2.y * p2.y) * (p3.x - p1.x)
    let c = (p3.x * p3.x + p3.y * p3.y) * (p1.x - p2.x)
    return a + b + c
}

fileprivate func calcD(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat {
    let a = (p1.x * p1.x + p1.y * p1.y) * (p3.x * p2.y - p2.x * p3.y)
    let b = (p2.x * p2.x + p2.y * p2.y) * (p1.x * p3.y - p3.x * p1.y)
    let c = (p3.x * p3.x + p3.y * p3.y) * (p2.x * p1.y - p1.x * p2.y)
    return a + b + c
}

public func calcCircle(_ point1: CGPoint, _ point2: CGPoint, _ point3: CGPoint) -> (center: CGPoint, radius: CGFloat)? {
    let a = calcA(point1, point2, point3)
    let b = calcB(point1, point2, point3)
    let c = calcC(point1, point2, point3)
    let d = calcD(point1, point2, point3)
    let center = CGPoint(x: -b / (2 * a), y: -c / (2 * a))
    let radius = sqrt((b * b + c * c - (4 * a * d)) / (4 * a * a))
    
    guard (!center.x.isNaN && !center.x.isInfinite) &&
            (!center.y.isNaN && !center.y.isInfinite) &&
            (!radius.isNaN && !radius.isInfinite) else
    {
        return nil
    }

    return (center, radius)
}
