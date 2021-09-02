//
//  PathProvider.swift
//  XCanvas
//
//  Created by chen on 2021/4/24.
//

import Foundation

public protocol CGPathProvider: Drawable {
    var cgPath: CGPath { get }
}

extension Array where Element == CGPathProvider {
    
    func combined() -> CGPath {
        self.map(\.cgPath)
            .reduce(CGMutablePath()) { result, path in
                result.addPath(path)
                return result
            }
    }
    
}
