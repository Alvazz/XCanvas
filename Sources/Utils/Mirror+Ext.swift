//
//  Mirror+Ext.swift
//  
//
//  Created by scchn on 2021/4/23.
//

import Foundation

extension Mirror {

    func properties<T>(ofType type: T.Type) -> [String: T] {
        var result: [String: T] = [:]
        
        for child in children {
            guard let propertyName = child.label, let value = child.value as? T else { continue }
            result[propertyName] = value
        }

        if let parent = superclassMirror {
            for (propertyName, value) in parent.properties(ofType: T.self) {
                result[propertyName] = value
            }
        }

        return result
    }
}
