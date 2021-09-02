//
//  CanvasView.swift
//  
//
//  Created by scchn on 2021/4/23.
//

import Cocoa
import AVFoundation.AVUtilities

@objc public protocol CanvasViewDelegate: NSObjectProtocol {
    @objc optional func canvasView(_ canvasView: CanvasView, didStartSession object: CanvasObject)
    @objc optional func canvasView(_ canvasView: CanvasView, didFinishSession object: CanvasObject)
    @objc optional func canvasView(_ canvasView: CanvasView, shouldDiscardFinishedObject object: CanvasObject) -> Bool
    @objc optional func canvasViewDidCancelSession(_ canvasView: CanvasView)
    
    @objc optional func canvasView(_ canvasView: CanvasView, didMove objects: [CanvasObject])
    @objc optional func canvasView(_ canvasView: CanvasView, didEdit object: CanvasObject, at indexPath: IndexPath)
    @objc optional func canvasView(_ canvasView: CanvasView, didRotate object: CanvasObject)
    @objc optional func canvasView(_ canvasView: CanvasView, didAnchor object: CanvasObject)
    
    @objc optional func canvasView(_ canvasView: CanvasView, didSelect objects: Set<CanvasObject>)
    @objc optional func canvasView(_ canvasView: CanvasView, didDeselect objects: Set<CanvasObject>)
    
    @objc optional func canvasView(_ canvasView: CanvasView, didDoubleClick object: CanvasObject)
    
    @objc optional func canvasView(_ canvasView: CanvasView, menuForObject object: CanvasObject?) -> NSMenu?
}

extension CanvasView {
    
    enum DrawingState {
        case idle
        case pressing
        case dragging
        case updating
    }
    
    enum State {
        case idle
        case selecting(CGRect)
        case drawing(CanvasObject, DrawingState)
        
        case onAnchor(CanvasObject, PointDescriptor)
        case anchoring(CanvasObject, PointDescriptor)
        
        /// [Object], [Init Rotation]
        case onRotator(CanvasObject, CGFloat, CGPoint)
        /// [Object], [Init Rotation]
        case rotating(CanvasObject, CGFloat, CGPoint)
        
        /// [Object], [Init Point], [Current Point]
        case onObject(CanvasObject, CGPoint, CGPoint)
        /// [Object], [Init Point], [Current Point]
        case dragging(CanvasObject, CGPoint, CGPoint)
        
        // [Object], [Index Path], [Init Point], [Current Point]
        case onPoint(CanvasObject, IndexPath, CGPoint, CGPoint)
        // [Object], [Index Path], [Init Point], [Current Point]
        case editing(CanvasObject, IndexPath, CGPoint, CGPoint)
    }
    
}

@objcMembers
open class CanvasView: NSView, CanvasStateManageable {
    
    private var notificationObservers: [NSObjectProtocol] = []
    private var trackingArea: NSTrackingArea?
    
    private var state: State = .idle
    
    private var contentRect: CGRect = .zero
    private var contentScaleFactors: CGPoint = .zero
    
    @objc dynamic private(set)
    open var objects: [CanvasObject] = []
    
    @objc dynamic private(set) 
    open var selectedObjects: [CanvasObject] = []
    
    open var currentObject: CanvasObject? {
        guard case .drawing(let object, _) = state else { return nil }
        return object
    }
    
    open var selectedObject: CanvasObject? {
        guard selectedObjects.count == 1 else { return nil }
        return selectedObjects.first
    }
    
    weak
    open var delegate: CanvasViewDelegate?
    
    // MARK: - Settings
    
    dynamic private(set)
    open var canvasSize: CGSize = .zero
    
    @CanvasState dynamic
    open var backgroundColor: NSColor = .lightGray
    
    @CanvasState dynamic
    open var foregroundColor: NSColor = .white
    
    //
    
    @CanvasState dynamic
    open var selectorBorderColor: NSColor = .lightGray
    
    @CanvasState dynamic
    open var selectorFillColor: NSColor = .init(red: 0, green: 1, blue: 1, alpha: 0.3)
    
    //
    
    @CanvasState dynamic
    open var selectionRadius: CGFloat = 10
    
    @CanvasState dynamic
    open var pointBorderColor: NSColor = .black
    
    @CanvasState dynamic
    open var pointFillColor: NSColor = .white
    
    //
    
    @CanvasState dynamic
    open var strokeColor: NSColor = .black
    
    @CanvasState dynamic
    open var fillColor: NSColor = .white
    
    @CanvasState dynamic
    open var lineWidth: CGFloat = 1
    
    @CanvasState(undoable: false) dynamic
    open var isObjectRotatable: Bool = false
    
    open var canUndoRotation: Bool {
        get { _isObjectRotatable.isUndoable }
        set { _isObjectRotatable.isUndoable = newValue }
    }
    
    //
    
    @CanvasState dynamic
    open var highlightedColor: NSColor = {
        guard #available(OSX 10.14, *) else { return .controlHighlightColor}
        return .controlAccentColor
    }()
    
    // MARK: - Life Cycle
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    public init(size: CGSize = .zero) {
        super.init(frame: .zero)
        commonInit()
    }
    
    private func commonInit() {
        setupStateManagement { [weak self] in
            self?.needsDisplay = true
        }
        
        let frameObserver = NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: self,
            queue: .main
        ) { notification in
            guard let canvasView = notification.object as? CanvasView else { return }
            canvasView.frameDidChange()
        }
        notificationObservers.append(frameObserver)
    }
    
    deinit {
        notificationObservers.forEach(NotificationCenter.default.removeObserver(_:))
    }
    
    open override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseEnteredAndExited, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        self.trackingArea = trackingArea
    }
    
    private func frameDidChange() {
        update()
    }
    
    private func update() {
        contentRect = AVMakeRect(aspectRatio: canvasSize, insideRect: bounds)
        contentScaleFactors = calcScaleFactors(from: contentRect.size, to: canvasSize)
        needsDisplay = true
    }
    
    // MARK: - Convenience Methods
    
    private func assertNonZeroSize(_ size: CGSize) {
        assert(size != .zero, "Canvas size must not be `.zero`")
    }
    
    open func convertPoint(_ point: CGPoint) -> CGPoint {
        point
            .applying(.init(translationX: -contentRect.minX, y: -contentRect.minY))
            .applying(.init(scaleX: contentScaleFactors.x, y: contentScaleFactors.y))
    }
    
    private func getConvertedPoint(from event: NSEvent) -> CGPoint {
        let point = convert(event.locationInWindow, from: nil)
        return convertPoint(point)
    }
    
    private func isValidPoint(_ convertedPoint: CGPoint) -> Bool {
        CGRect(origin: .zero, size: canvasSize).contains(convertedPoint)
    }
    
    private func object(at convertedPoint: CGPoint) -> CanvasObject? {
        let selecteds = selectedObjects.reversed()
            
        if let object = selecteds.first(where: { $0.hitTest(convertedPoint, range: selectionRadius) }) {
            return object
        }
        
        let unselecteds = objects.filter({ !selectedObjects.contains($0) }).reversed()
        
        return unselecteds.first { $0.hitTest(convertedPoint, range: selectionRadius) }
    }
    
    private func objectOfAnchor(at convertedPoint: CGPoint) -> CanvasObject? {
        guard isObjectRotatable,
              let object = selectedObject,
              object.isRotatable,
              object.drawingStrategy.isDefault
        else { return nil }
        let centerDesc = object.rotationCenter
        let center = object.getPoint(with: centerDesc)
        return center.contains(convertedPoint, in: selectionRadius) ? object : nil
    }
    
    private func objectOfRotator(at convertedPoint: CGPoint) -> CanvasObject? {
        guard isObjectRotatable,
              let object = selectedObject,
              object.isRotatable,
              object.drawingStrategy.isDefault
        else { return nil }
        let center = object.getPoint(with: object.rotationCenter)
        let onRotator = center.contains(convertedPoint, in: selectionRadius * 2) &&
            !center.contains(convertedPoint, in: selectionRadius)
        return onRotator ? object : nil
    }
    
    private func pointIndexPathOfObject(at convertedPoint: CGPoint) -> (CanvasObject, IndexPath)? {
        for object in selectedObjects.reversed() where object.drawingStrategy.isDefault {
            if let indexPath = object.indexPath(at: convertedPoint, range: selectionRadius) {
                return (object, indexPath)
            }
        }
        return nil
    }
    
    // MARK: -
    
    public func updateCanvasSize(_ size: CGSize) {
        assertNonZeroSize(size)
        
        guard size != canvasSize else { return }
        
        let scaleFactors = calcScaleFactors(from: canvasSize, to: size)
        
        currentObject?.scale(x: scaleFactors.x, y: scaleFactors.y)
        
        for object in objects {
            object.scale(x: scaleFactors.x, y: scaleFactors.y)
        }
        
        canvasSize = size
        update()
    }
    
    open func addObjects(_ objectsToAdd: [CanvasObject]) {
        assertNonZeroSize(canvasSize)
        
        let objectsToAdd = objectsToAdd.filter { !objects.contains($0) }
        var addedObject: [CanvasObject] = []
        for object in objectsToAdd where !objects.contains(object) {
            guard object.markAsFinished() else { continue }
            object.undoManager = undoManager
            object.redrawHandler = { [weak self] object in
                self?.needsDisplay = true
            }
            addedObject.append(object)
            objects.append(object)
        }
        
        guard !addedObject.isEmpty else { return }
        registerUndoAddObjects(addedObject)
        needsDisplay = true
    }
    
    open func removeObjects(_ objectsToRemove: [CanvasObject]) {
        var removedObjects: [CanvasObject] = []
        for object in objectsToRemove where objects.contains(object) {
            guard let index = objects.firstIndex(of: object) else { continue }
            let object = objects.remove(at: index)
            object.redrawHandler = nil
            object.undoManager = nil
            removedObjects.append(object)
        }
        
        guard !removedObjects.isEmpty else { return }
        deselectObjects(removedObjects)
        registerUndoRemoveObjects(removedObjects, canvasSize: canvasSize)
        state = .idle
        needsDisplay = true
    }
    
    open func removeSelectedObjects() {
        removeObjects(selectedObjects)
    }
    
    open func removeAllObjects() {
        removeObjects(objects)
    }
    
    private func _selectObjects(_ objectsToSelect: [CanvasObject], extending: Bool = false) {
        let selection = !extending ? objectsToSelect : selectedObjects + Set(objectsToSelect).subtracting(selectedObjects)
        let addeds = Set(selection).subtracting(selectedObjects)
        let removeds = Set(selectedObjects).subtracting(selection)
        selectedObjects.removeAll(where: removeds.contains)
        selectedObjects.append(contentsOf: addeds)
        if !addeds.isEmpty {
            delegate?.canvasView?(self, didSelect: addeds)
        }
        if !removeds.isEmpty {
            delegate?.canvasView?(self, didDeselect: removeds)
        }
        needsDisplay = true
    }
    
    open func selectObjects(_ objectsToSelect: [CanvasObject], byExtendingSelection extending: Bool = false) {
        let objectsToSelect = objectsToSelect.filter(objects.contains)
        _selectObjects(objectsToSelect, extending: extending)
    }
    
    open func selectAllObjects() {
        _selectObjects(objects)
    }
    
    open func deselectObjects(_ objectsToDeselect: [CanvasObject]) {
        let objects = selectedObjects.filter { !objectsToDeselect.contains($0) }
        _selectObjects(objects)
    }
    
    open func deselectAllObjects() {
        _selectObjects([])
    }
    
    // MARK: - Drawing Session
    
    open func discardCurrentObject() {
        guard case .drawing = state else { return }
        state = .idle
        delegate?.canvasViewDidCancelSession?(self)
        needsDisplay = true
    }
    
    open func stopDrawingSession() {
        guard case .drawing(let object, _) = state else { return }
        state = .idle
        
        let shouldDiscard = delegate?.canvasView?(self, shouldDiscardFinishedObject: object) ?? false
        
        if object.isFinishable && !shouldDiscard {
            addObjects([object])
            delegate?.canvasView?(self, didFinishSession: object)
        } else {
            delegate?.canvasViewDidCancelSession?(self)
        }
        needsDisplay = true
    }
    
    @discardableResult
    open func startDrawingSession(ofType type: CanvasObject.Type) -> CanvasObject {
        assertNonZeroSize(canvasSize)
        
        stopDrawingSession()
        _selectObjects([])
        
        let object = type.init()
        object.strokeColor = strokeColor
        object.fillColor = fillColor
        object.lineWidth = lineWidth
        object.redrawHandler = { [weak self] object in
            self?.needsDisplay = true
        }
        state = .drawing(object, .idle)
        delegate?.canvasView?(self, didStartSession: object)
        needsDisplay = true
        
        return object
    }
    
    // MARK: - Undo
    
    open func registerUndoAction(name: String?, _ handler: @escaping (CanvasView) -> Void) {
        undoManager?.registerUndo(withTarget: self, handler: handler)
        if let name = name {
            undoManager?.setActionName(name)
        }
    }
    
    open func registerUndoAddObjects(_ objects: [CanvasObject]) {
        guard !objects.isEmpty else { return }
        registerUndoAction(name: nil) { canvasView in
            canvasView.removeObjects(objects)
        }
    }
    
    open func registerUndoRemoveObjects(_ objects: [CanvasObject], canvasSize: CGSize) {
        guard !objects.isEmpty else { return }
        registerUndoAction(name: nil) { canvasView in
            let scaleFactors = calcScaleFactors(from: canvasSize, to: canvasView.canvasSize)
            objects.forEach { $0.scale(x: scaleFactors.x, y: scaleFactors.y) }
            canvasView.addObjects(objects)
        }
    }
    
    open func registerUndoMoveObjects(_ objects: [CanvasObject], x: CGFloat, y: CGFloat, canvasSize: CGSize) {
        registerUndoAction(name: nil) { canvasView in
            let scaleFactors = calcScaleFactors(from: canvasSize, to: canvasView.canvasSize)
            let dx = -x * scaleFactors.x
            let dy = -y * scaleFactors.y
            objects.forEach { $0.translate(x: dx, y: dy) }
            canvasView.delegate?.canvasView?(canvasView, didMove: objects)
            canvasView.registerUndoMoveObjects(objects, x: dx, y: dy, canvasSize: canvasView.canvasSize)
        }
    }
    
    open func registerUndoEdit(_ object: CanvasObject, at indexPath: IndexPath, x: CGFloat, y: CGFloat, canvasSize: CGSize) {
        registerUndoAction(name: nil) { canvasView in
            let scaleFactors = calcScaleFactors(from: canvasSize, to: canvasView.canvasSize)
            let dx = -x * scaleFactors.x
            let dy = -y * scaleFactors.y
            object.translate(x: dx, y: dy, at: indexPath)
            canvasView.delegate?.canvasView?(canvasView, didEdit: object, at: indexPath)
            canvasView.registerUndoEdit(object, at: indexPath, x: dx, y: dy, canvasSize: canvasView.canvasSize)
        }
    }
    
    open func registerUndoRotation(_ object: CanvasObject, rotation: CGFloat) {
        registerUndoAction(name: nil) { canvasView in
            canvasView.registerUndoRotation(object, rotation: object.rotation)
            object.rotate(.radians(rotation))
            canvasView.delegate?.canvasView?(canvasView, didRotate: object)
        }
    }
    
    private func registerUndoAnchoring(_ object: CanvasObject, at center: PointDescriptor) {
        registerUndoAction(name: nil) { canvasView in
            canvasView.registerUndoAnchoring(object, at: object.rotationCenter)
            object.setRotationCenter(center)
            canvasView.delegate?.canvasView?(canvasView, didAnchor: object)
        }
    }
    
    // MARK: - Mouse Events
    
    open override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        let point = getConvertedPoint(from: event)
        
        guard isValidPoint(point) else { return }
        
        switch state {
        case .idle:
            if let object = objectOfAnchor(at: point) {
                state = .onAnchor(object, object.rotationCenter)
            } else if let object = objectOfRotator(at: point) {
                state = .onRotator(object, object.rotation, point)
            } else if let (object, indexPath) = self.pointIndexPathOfObject(at: point) {
                _selectObjects([object])
                state = .onPoint(object, indexPath, point, point)
            } else if let object = object(at: point) {
                if !selectedObjects.contains(object) {
                    _selectObjects([object])
                }
                state = .onObject(object, point, point)
            } else {
                let rect = CGRect(origin: point, size: .zero)
                _selectObjects([])
                state = .selecting(rect)
            }
        case let .drawing(object, mode):
            switch object.drawingStrategy {
            case .default(let action):
                guard mode != .updating else {
                    object.updateLast(point: point)
                    break
                }
                if object.isEmpty || action() == .pushToNext {
                    object.push(point: point)
                }
                object.push(point: point)
                state = .drawing(object, .pressing)
            case .continuous:
                object.pushToNext(point)
            }
        default:
            break
        }
        
        needsDisplay = true
    }
    
    open override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        
        let point = getConvertedPoint(from: event)
        
        switch state {
        case .selecting(var rect):
            rect.size = CGSize(width: point.x - rect.origin.x, height: point.y - rect.origin.y)
            let selectedObjects = objects.reduce([CanvasObject]()) { objects, object in
                object.selectTest(rect) ? objects + [object] : objects
            }
            _selectObjects(selectedObjects)
            state = .selecting(rect)
        case let .drawing(object, mode) where !object.isEmpty:
            switch object.drawingStrategy {
            case .default:
//            case .default(let action):
//                let action = action()
//                if mode == .updating, (action == .push || action == .pushOrFinish) {
//                    object.push(point: point)
//                }
                object.updateLast(point: point)
            case .continuous:
                object.push(point: point)
            }
            if mode != .dragging {
                state = .drawing(object, .dragging)
            }
            
        case let .onAnchor(object, initCenter): fallthrough
        case let .anchoring(object, initCenter):
            if let indexPath = object.indexPath(at: point, range: selectionRadius) {
                object.setRotationCenter(.indexPath(indexPath))
            } else {
                object.setRotationCenter(.point(point))
            }
            state = .anchoring(object, initCenter)
            
            delegate?.canvasView?(self, didAnchor: object)
            
        case let .onRotator(object, initRotation, lastPoint): fallthrough
        case let .rotating(object, initRotation, lastPoint):
            let center = object.getPoint(with: object.rotationCenter)
            let prev = Line(from: center, to: lastPoint).angle
            let curr = Line(from: center, to: point).angle
            let rotation = object.rotation + (curr - prev)
            object.rotate(.radians(rotation))
            state = .rotating(object, initRotation, point)
            
            delegate?.canvasView?(self, didRotate: object)
            
        case let .onPoint(object, indexPath, initPoint, lastPoint): fallthrough
        case let .editing(object, indexPath, initPoint, lastPoint):
            let dx = point.x - lastPoint.x, dy = point.y - lastPoint.y
            object.translate(x: dx, y: dy, at: indexPath)
            state = .editing(object, indexPath, initPoint, point)
            
            delegate?.canvasView?(self, didEdit: object, at: indexPath)
            
        case let .onObject(object, initPoint, lastPoint): fallthrough
        case let .dragging(object, initPoint, lastPoint):
            let dx = point.x - lastPoint.x, dy = point.y - lastPoint.y
            selectedObjects.forEach { $0.translate(x: dx, y: dy) }
            state = .dragging(object, initPoint, point)
            
            delegate?.canvasView?(self, didMove: selectedObjects)
            
        default:
            break
        }
        
        needsDisplay = true
    }
    
    open override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        let point = getConvertedPoint(from: event)
        
        switch state {
        case .selecting:
            state = .idle
        case let .drawing(object, mode):
            guard !object.isEmpty else { break }
            
            switch object.drawingStrategy {
            case let .default(action):
                let action = action()
                
                switch mode {
                case .pressing where object.last?.count != 1:
                    state = .drawing(object, .updating)
                case .updating where (action == .push || action == .pushOrFinish):
                    object.push(point: point)
                default:
                    if action == .finish {
                        stopDrawingSession()
                    } else {
                        state = .drawing(object, .idle)
                    }
                }
            case let .continuous(range):
                if (range?.upperBound ?? .max) > object.count {
                    object.push(point: point)
                } else {
                    stopDrawingSession()
                }
            }
        case let .anchoring(object, initCenter):
            if object.rotationCenter != initCenter {
                registerUndoAnchoring(object, at: initCenter)
            }
            state = .idle
        case let .rotating(object, initRotation, _):
            registerUndoRotation(object, rotation: initRotation)
            state = .idle
        case let .onObject(object, _, _):
            _selectObjects([object])
            state = .idle
            if event.clickCount == 2 {
                delegate?.canvasView?(self, didDoubleClick: object)
            }
        case let .dragging(_, start, _):
            let dx = point.x - start.x, dy = point.y - start.y
            registerUndoMoveObjects(selectedObjects, x: dx, y: dy, canvasSize: canvasSize)
            state = .idle
        case let .editing(object, indexPath, initPoint, _):
            let dx = point.x - initPoint.x, dy = point.y - initPoint.y
            registerUndoEdit(object, at: indexPath, x: dx, y: dy, canvasSize: canvasSize)
            state = .idle
        default:
            state = .idle
        }
        
        needsDisplay = true
    }
    
    open override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        
        switch state {
        case let .drawing(object, mode):
            if mode == .updating {
                let point = getConvertedPoint(from: event)
                object.updateLast(point: point)
                needsDisplay = true
            }
        default:
            break
        }
    }
    
    open override func menu(for event: NSEvent) -> NSMenu? {
        guard window?.isKeyWindow == true else { return nil }
        guard event.type == .rightMouseDown, case .idle = state else { return super.menu(for: event) }
        
        let point = getConvertedPoint(from: event)
        
        guard isValidPoint(point) else {
            return super.menu(for: event)
        }
        
        let object = object(at: point)
        
        if let object = object {
            if !selectedObjects.contains(object) {
                _selectObjects([object])
            }
        } else {
            deselectAllObjects()
        }
        
        return delegate?.canvasView?(self, menuForObject: object)
    }
    
    open override func rightMouseDown(with event: NSEvent) {
        super.rightMouseDown(with: event)
        
        switch state {
        case .drawing:
            stopDrawingSession()
            deselectAllObjects()
        default:
            break
        }
    }
    
    // MARK: - Drawing
    
    private func _draw(bounds: CGRect, contentRect: CGRect, scaleFactors: CGPoint) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        
        backgroundColor.setFill()
        bounds.fill()
        
        foregroundColor.setFill()
        contentRect.fill()
        
        ctx.clip(to: contentRect)
        ctx.translateBy(x: contentRect.origin.x, y: contentRect.origin.y)
        ctx.scaleBy(x: 1 / scaleFactors.x, y: 1 / scaleFactors.y)
        
        let rect = CGRect(origin: .zero, size: canvasSize)
        var drawsPoints: Bool = true
        var pointMark: (CanvasObject, IndexPath)?
        var highlightsRotator: Bool = false
        var auxiliaryLine: (CanvasObject, IndexPath, AuxiliaryLineStyle)?
        
        switch state {
        case let .drawing(object, subState):
            if subState != .idle, object is AuxiliaryLineDrawable, let points = object.last {
                let section = object.count - 1
                let item = points.count - 1
                auxiliaryLine = (object, IndexPath(item: item, section: section), .disconnected)
            }
        case .onAnchor, .anchoring, .onRotator, .rotating:
            highlightsRotator = true
        case let .onPoint(object, indexPath, _, _):
            pointMark = (object, indexPath)
        case let .editing(object, indexPath, _, _):
            if let aux = object as? AuxiliaryLineDrawable {
                auxiliaryLine = (object, indexPath, aux.auxiliaryLineStyle)
            }
            fallthrough
        case .dragging:
            drawsPoints = false
        default:
            break
        }
        
        for object in objects where !selectedObjects.contains(object) {
            object.draw(rect, in: ctx)
        }
        
        for object in selectedObjects {
            object.draw(rect, in: ctx)
            
            if object.drawingStrategy.isDefault, drawsPoints {
                // Points
                let indexPath: IndexPath? = (pointMark?.0 == object ? pointMark?.1 : nil)
                for (section, points) in object.enumerated() {
                    for (item, point) in points.enumerated() {
                        let isHighlighted = indexPath == IndexPath(item: item, section: section)
                        drawPoint(at: point, highlighted: isHighlighted, in: ctx)
                    }
                }
                // Rotator
                if selectedObjects.count == 1, isObjectRotatable, object.isRotatable {
                    drawRotator(object: object, highlighted: highlightsRotator, in: ctx)
                }
            }
            
            // Rect
            if !object.drawingStrategy.isDefault, let frame = object.path?.boundingBoxOfPath {
                let inset = -selectionRadius
                let rect = frame.insetBy(dx: inset, dy: inset)
                drawRectangle(rect, stroke: highlightedColor, fill: .clear, in: ctx)
            }
        }
        
        currentObject?.draw(rect, in: ctx)
        
        if let (object, indexPath, style) = auxiliaryLine {
            let isConnected = style == .connected
            drawAuxiliaryLine(object: object, connected: isConnected, at: indexPath, in: ctx)
        }
        
        if case let .selecting(rect) = state {
            drawRectangle(rect, stroke: selectorBorderColor, fill: selectorFillColor, in: ctx)
        }
    }
    
    open func drawSnapshotShot(size: CGSize, objectsOnly: Bool = false) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        
        ctx.saveGState()
        defer { ctx.restoreGState() }
        
        let bounds = CGRect(origin: .zero, size: size)
        let contentRect = AVMakeRect(aspectRatio: canvasSize, insideRect: bounds)
        let scaleFactors = calcScaleFactors(from: size, to: canvasSize)
        
        if objectsOnly {
            backgroundColor.setFill()
            bounds.fill()
            
            foregroundColor.setFill()
            contentRect.fill()
            
            ctx.clip(to: contentRect)
            ctx.translateBy(x: contentRect.origin.x, y: contentRect.origin.y)
            ctx.scaleBy(x: 1 / scaleFactors.x, y: 1 / scaleFactors.y)
            
            let rect = CGRect(origin: .zero, size: canvasSize)
            for object in objects {
                object.draw(rect, in: ctx)
            }
        } else {
            _draw(bounds: bounds, contentRect: contentRect, scaleFactors: scaleFactors)
        }
    }
    
    open override func draw(_ dirtyRect: NSRect) {
        _draw(bounds: bounds, contentRect: contentRect, scaleFactors: contentScaleFactors)
    }
    
    open func drawPoint(at point: CGPoint, highlighted: Bool, in ctx: CGContext) {
        ctx.setFillColor(highlighted ? highlightedColor.cgColor : .white)
        ctx.setStrokeColor(.black)
        ctx.addCircle(center: point, radius: selectionRadius)
        ctx.drawPath(using: .fillStroke)
    }
    
    open func drawRotator(object: CanvasObject, highlighted: Bool, in ctx: CGContext) {
        let point = object.getPoint(with: object.rotationCenter)
        let len = selectionRadius * 0.6
        
        ctx.setStrokeColor(highlighted ? highlightedColor.cgColor : .black)
        ctx.setFillColor(highlighted ? highlightedColor.cgColor : .black)
        
        // Draw Crosshair
        ctx.addLines(between: [
            CGPoint(x: point.x - len, y: point.y),
            CGPoint(x: point.x + len, y: point.y),
        ])
        ctx.addLines(between: [
            CGPoint(x: point.x, y: point.y - len),
            CGPoint(x: point.x, y: point.y + len),
        ])
        ctx.strokePath()
        // Draw Arc
        let radius = selectionRadius * 1.5
        let start = object.rotation - .pi / 4
        let end = object.rotation + .pi / 4
        ctx.addArc(center: point, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        ctx.strokePath()
        // Draw Arrows
        ctx.addArrow(
            at: point.extended(length: radius, angle: start),
            width: len,
            rotation: -.pi / 2 * 1.5 + object.rotation
        )
        ctx.addArrow(
            at: point.extended(length: radius, angle: end),
            width: len,
            rotation: .pi / 2 * 1.5 + object.rotation
        )
        ctx.fillPath()
    }
    
    private func drawAuxiliaryLine(object: CanvasObject, connected: Bool, at indexPath: IndexPath, in ctx: CGContext) {
        guard object[indexPath.section].count > 1 else { return }
        
        CGPathDescriptor(method: .defaultDash(width: object.lineWidth), color: object.strokeColor) { path in
            let endIndexPath = IndexPath(item: indexPath.item + (indexPath.item == 0 ? 1 : -1), section: indexPath.section)
            let start = object[indexPath]
            let end = object[endIndexPath]
            let line = Line(from: start, to: end)
            let len = line.distance / 2
            let angle = line.angle
            if connected {
                path.addLine(line)
            }
            [start, end].forEach { point in
                path.addLines(between: [
                    point.extended(length: len, angle: angle + .pi / 2),
                    point.extended(length: len, angle: angle - .pi / 2),
                ])
            }
        }
        .draw(in: ctx)
    }
    
    private func drawRectangle(_ rect: CGRect, stroke: NSColor, fill: NSColor, in ctx: CGContext) {
        ctx.setLineWidth(1)
        ctx.setStrokeColor(stroke.cgColor)
        ctx.setFillColor(fill.cgColor)
        ctx.addRect(rect)
        ctx.drawPath(using: .fillStroke)
    }
    
}
