//
//  CanvasState.swift
//  XCanvas
//
//  Created by scchn on 2021/4/26.
//

import Foundation

fileprivate protocol Observable {
    var undoable: Bool { get }
    var updateHandler: ((Any, Any) -> Void)? { get set }
}

/// Make sure the wrapped value is Objective-C compatible.
@propertyWrapper
public class CanvasState<T>: Observable {
    
    fileprivate var updateHandler: ((Any, Any) -> Void)?
    fileprivate let undoable: Bool
    
    public var wrappedValue: T {
        didSet { updateHandler?(oldValue, wrappedValue) }
    }
    
    public init(wrappedValue: T, undoable: Bool = true) {
        self.wrappedValue = wrappedValue
        self.undoable = undoable
    }
    
}

protocol CanvasStateManageable: NSObject {
    var undoManager: UndoManager? { get }
}

extension CanvasStateManageable {
    
    func setupStateManagement(_ updateHandler: @escaping () -> Void) {
        let mirror = Mirror(reflecting: self)
        let properties = mirror.properties(ofType: Observable.self)
        
        for (key, var value) in properties {
            value.updateHandler = { [weak self] old, new in
                if old is NSObject && value.undoable {
                    let keyPath = String(key.dropFirst())
                    self?.registerStateUndoAction(keyPath: keyPath, value: old)
                }
                updateHandler()
            }
        }
    }
    
    private func registerStateUndoAction(keyPath: String, value: Any) {
        undoManager?.registerUndo(withTarget: self) { object in
            // Redo
            if let curr = object.value(forKey: keyPath) {
                object.registerStateUndoAction(keyPath: keyPath, value: curr)
            }
            // Undo
            object.undoManager?.disableUndoRegistration()
            object.setValue(value, forKey: keyPath)
            object.undoManager?.enableUndoRegistration()
        }
    }
    
}
