//
//  CanvasObjectTypeConvertible.swift
//  
//
//  Created by scchn on 2021/5/5.
//

import Foundation

public enum CanvasObjectConversionError: Error {
    case noIdentifierProvided
    case undefinedIdentifier
}

public protocol CanvasObjectTypeConvertible {
    
    var objectType: CanvasObject.Type { get }
    
    init?(identifier: CanvasObject.Identifier)
    
}

extension CanvasObjectTypeConvertible {
    
    public static func convert(object: CanvasObject) -> Result<CanvasObject, CanvasObjectConversionError> {
        guard let identifier = object.identifier else {
            return .failure(.noIdentifierProvided)
        }
        guard let converter = Self.init(identifier: identifier) else {
            return .failure(.undefinedIdentifier)
        }
        let object = object.convert(to: converter.objectType)
        return .success(object)
    }
    
}
