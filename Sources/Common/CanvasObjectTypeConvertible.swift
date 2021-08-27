//
//  CanvasObjectTypeConvertible.swift
//  
//
//  Created by scchn on 2021/5/5.
//

import Foundation

public enum CanvasObjectConversionError: Error {
    case undefinedIdentifier
    case finishObjectFailed
}

public protocol CanvasObjectTypeConvertible {
    init?(identifier: CanvasObject.Identifier)
    var objectType: CanvasObject.Type { get }
}

extension CanvasObjectTypeConvertible {
    
    public static func convert(object: CanvasObject) throws -> CanvasObject {
        guard let id = object.identifier, let converter = Self.init(identifier: id) else {
            throw CanvasObjectConversionError.undefinedIdentifier
        }
        
        return object.convert(to: converter.objectType)
    }
    
}
