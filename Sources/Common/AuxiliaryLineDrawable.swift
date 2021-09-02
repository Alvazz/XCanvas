//
//  AuxiliaryLineDrawable.swift
//  
//
//  Created by chen on 2021/5/10.
//

import Foundation

public enum AuxiliaryLineStyle {
    case connected
    case disconnected
}

public protocol AuxiliaryLineDrawable {
    var auxiliaryLineStyle: AuxiliaryLineStyle { get }
}
