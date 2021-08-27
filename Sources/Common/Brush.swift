//
//  Brush.swift
//  XCanvas
//
//  Created by chen on 2021/4/24.
//

import Foundation

public protocol Brush {
    func draw(in ctx: CGContext)
}
