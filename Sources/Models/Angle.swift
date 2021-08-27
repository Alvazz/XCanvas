//
//  Angle.swift
//  XCanvas
//
//  Created by chen on 2021/4/24.
//

import Foundation

public enum Angle {

    case radians(CGFloat)
    case degrees(CGFloat)
    
    public func toDegrees() -> Angle {
        guard case .radians(let r) = self else { return self }
        return .degrees(r / .pi * 180)
    }
    
    public func toRadians() -> Angle {
        guard case .degrees(let d) = self else { return self }
        return .radians(d * .pi / 180)
    }
    
    public var value: CGFloat {
        switch self {
        case .degrees(let v): fallthrough
        case .radians(let v): return v
        }
    }
    
}
