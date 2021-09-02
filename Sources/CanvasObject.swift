//
//  CanvasObject.swift
//  
//
//  Created by scchn on 2021/4/23.
//

import Cocoa

extension CanvasObject {
    
    public struct Identifier: RawRepresentable, Equatable, Hashable, Codable {
        public var rawValue: String
        
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
    }
    
    public enum DefaulStrategyAction {
        case push
        case pushToNext
        case pushOrFinish
        case finish
        
        public var isPushable: Bool { self != .finish }
        public var isFinishable: Bool { self == .pushOrFinish || self == .finish }
    }
    
    public enum DrawingStrategy {
        case `default`(() -> DefaulStrategyAction)
        case continuous(ClosedRange<Int>?)
        
        public var isDefault: Bool {
            guard case .default = self else { return false }
            return true
        }
        
    }
    
    public struct Relation {
        public var indexPath: IndexPath
        public var offset: CGPoint
        
        public init(indexPath: IndexPath, offset: CGPoint) {
            self.indexPath = indexPath
            self.offset = offset
        }
    }
    
}

@objcMembers
open class CanvasObject: NSObject, CanvasStateManageable, Codable, NSCopying {
    
    public static let tagDidChangeNotification = Notification.Name("com.scchn.XCanvas.tagDidChangeNotification")
    
    private var counter = 0
    
    private var layout = Layout() {
        didSet {
            didUpdateLayout()
            update()
        }
    }
    
    private var layoutBrushes: [Drawable] = []

    private var objectBrushes: [Drawable] = []
    
    open var path: CGPath? {
        objectBrushes.compactMap { $0 as? CGPathProvider }.combined()
    }
    
    private var userInfo: Data?
    
    private(set)
    open var identifier: Identifier? = nil
    
    private(set)
    open var rotationCenter: PointDescriptor = .indexPath(IndexPath(item: 0, section: 0))
    
    private(set)
    open var rotation: CGFloat = 0
    
    
    // MARK: - Auto-Redraw Properties
    
    weak var undoManager: UndoManager?
    
    var redrawHandler: ((CanvasObject) -> Void)?

    @CanvasState
    open var strokeColor: NSColor = .black

    @CanvasState
    open var fillColor: NSColor = .black

    @CanvasState
    open var lineWidth: CGFloat = 1
    
    @CanvasState private(set)
    open var tag: String = "" {
        didSet {
            NotificationCenter.default.post(name: Self.tagDidChangeNotification, object: self)
        }
    }
    
    
    // MARK: - Drawing Rules
    
    open var isRotatable: Bool { true }
    
    open var drawingStrategy: DrawingStrategy { .default { .push } }
    
    open var isFinishable: Bool {
        switch drawingStrategy {
        case .default(let action): return action().isFinishable
        case .continuous(let range): return !isEmpty && range?.contains(count) != false
        }
    }
    
    open private(set) var isFinished: Bool = false
    
    // MARK: - Life Cycle
    
    public required override init() {
        super.init()
        setupStateManagement { [weak self] in
            self?.update()
        }
    }
    
    open subscript(_ indexPath: IndexPath) -> CGPoint {
        get {
            self[indexPath.section][indexPath.item]
        }
        set(point) {
            update(point: point, at: indexPath)
        }
    }
    
    
    // MARK: - Editing Methods
    
    func getPoint(with descriptor: PointDescriptor) -> CGPoint {
        switch descriptor {
        case let .indexPath(indexPath): return self[indexPath.section][indexPath.item]
        case let .point(point):         return point
        }
    }
    
    open func relations() -> [IndexPath: [Relation]] {
        [:]
    }
    
    open func update() {
        layoutBrushes = isFinished ? [] : createLayoutBrushes()
        objectBrushes = !isFinishable ? [] : createObjectBrushes()
        redrawHandler?(self)
    }
    
    func pushToNext(_ point: CGPoint) {
        guard case .continuous = drawingStrategy else { return }
        layout.push(point, next: true)
    }
    
    open func push(point: CGPoint) {
        switch drawingStrategy {
        case let .default(action):
            let action = action()
            guard action != .finish else { return }
            layout.push(point, next: action == .pushToNext)
        case .continuous:
            layout.push(point)
        }
    }
    
    open func update(point: CGPoint, at indexPath: IndexPath) {
        let current = layout[indexPath.section][indexPath.item]
        var newLayout = layout
        
        newLayout.update(point, section: indexPath.section, item: indexPath.item)
        
        if isFinishable, let relations = relations()[indexPath] {
            let center = getPoint(with: rotationCenter)
            let line = Line(
                from: current.rotated(origin: center, angle: -rotation),
                to: point.rotated(origin: center, angle: -rotation)
            )
            
            for relation in relations {
                let section = relation.indexPath.section
                let item = relation.indexPath.item
                let dx = line.dx * relation.offset.x
                let dy = line.dy * relation.offset.y
                let point = newLayout[section][item]
                    .rotated(origin: center, angle: -rotation)
                    .applying(.init(translationX: dx, y: dy))
                    .rotated(origin: center, angle: rotation)
                
                newLayout.update(point, section: section, item: item)
            }
        }
        
        layout = newLayout
    }
    
    open func updateLast(point: CGPoint) {
        let section = endIndex - 1
        let item = self[section].endIndex - 1
        let indexPath = IndexPath(item: item, section: section)
        update(point: point, at: indexPath)
    }
    
    open func translate(x: CGFloat, y: CGFloat, at indexPath: IndexPath) {
        let point = self[indexPath.section][indexPath.item]
            .applying(.init(translationX: x, y: y))
        update(point: point, at: indexPath)
    }
    
    open func translate(x: CGFloat, y: CGFloat) {
        var newLayout = layout
        
        for (section, points) in layout.enumerated() {
            for (item, point) in points.enumerated() {
                let point = CGPoint(x: point.x + x, y: point.y + y)
                newLayout.update(point, section: section, item: item)
            }
        }
        
        layout = newLayout
    }
    
    open func setRotationCenter(_ descriptor: PointDescriptor) {
        guard isFinished else { fatalError("Can't set rotation center for a unfinished object") }
        rotationCenter = descriptor
        update()
    }
    
    open func rotate(_ angle: Angle) {
        guard isFinished else { fatalError("Can't rotate a unfinished object") }
        
        let center = getPoint(with: rotationCenter)
        let radians = angle.toRadians().value
        let dAngle = radians - rotation
        var newLayout = layout
        
        for (section, points) in layout.enumerated() {
            for (item, point) in points.enumerated() {
                let point = point.rotated(origin: center, angle: dAngle)
                newLayout.update(point, section: section, item: item)
            }
        }
        
        rotation = radians
        
        layout = newLayout
    }
    
    open func scale(x: CGFloat, y: CGFloat) {
        var newLayout = layout
        
        for (section, points) in layout.enumerated() {
            for (item, point) in points.enumerated() {
                let point = point.applying(.init(scaleX: x, y: y))
                newLayout.update(point, section: section, item: item)
            }
        }
        
        layout = newLayout
    }
    
    @discardableResult
    open func markAsFinished() -> Bool {
        guard isFinishable else { return false }
        guard !isFinished else { return true }
        isFinished = true
        update()
        return true
    }
    
    open func didUpdateLayout() {
        
    }
    
    open func updateTag(_ newTag: String) {
        let newTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if newTag != tag {
            tag = newTag
        }
    }
    
    
    // MARK: - Drawing
    
    open func createLayoutBrushes() -> [Drawable] {
        let path = layout.reduce(CGMutablePath()) { path, items in
            path.addLines(between: items)
            return path
        }
        let descriptor = CGPathDescriptor(
            method: .defaultDash(width: lineWidth),
            color: strokeColor,
            path: path
        )
        return [descriptor]
    }
    
    open func createObjectBrushes() -> [Drawable] {
        let path = layout.reduce(CGMutablePath()) { path, items in
            path.addLines(between: items)
            return path
        }
        let descriptor = CGPathDescriptor(
            method: .stroke(width: lineWidth),
            color: strokeColor,
            path: path
        )
        return [descriptor]
    }
    
    open func draw(_ rect: CGRect, in ctx: CGContext) {
        layoutBrushes.forEach { $0.draw(in: ctx) }
        objectBrushes.forEach { $0.draw(in: ctx) }
    }
    
    
    // MARK: - Selection Tests
    
    open func indexPath(at point: CGPoint, range: CGFloat) -> IndexPath? {
        for (i, points) in self.reversed().enumerated() {
            for (j, aPoint) in points.reversed().enumerated() {
                if aPoint.contains(point, in: range) {
                    let section = self.count - i - 1
                    let item = points.count - j - 1
                    return IndexPath(item: item, section: section)
                }
            }
        }
        return nil
    }
    
    open func hitTest(_ point: CGPoint, range: CGFloat) -> Bool {
        let pathDescs = objectBrushes.compactMap { $0 as? CGPathDescriptor }
        for desc in pathDescs {
            if desc.contains(point: point, range: range) {
                return true
            }
        }
        return false
    }
    
    open func selectTest(_ rect: CGRect) -> Bool {
        for points in self where !points.isEmpty {
            if points.count > 1 {
                for (i, point) in points[1...].enumerated() {
                    let line = Line(from: points[i], to: point)
                    if rect.canSelect(line) {
                        return true
                    }
                }
            } else if rect.contains(points[0]) {
                return true
            }
        }
        return false
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case identifier
        case layout
        case rotationCenter
        case rotation
        case strokeColor
        case fillColor
        case lineWidth
        case isFinished
        case userInfo
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        identifier     = try container.decodeIfPresent(Identifier.self, forKey: .identifier)
        layout         = try container.decode(Layout.self, forKey: .layout)
        rotationCenter = try container.decode(PointDescriptor.self, forKey: .rotationCenter)
        rotation       = try container.decode(CGFloat.self, forKey: .rotation)
        strokeColor    = try container.decode(XColor.self, forKey: .strokeColor).nsColor
        fillColor      = try container.decode(XColor.self, forKey: .fillColor).nsColor
        lineWidth      = try container.decode(CGFloat.self, forKey: .lineWidth)
        isFinished     = try container.decode(Bool.self, forKey: .isFinished)
        userInfo       = try container.decodeIfPresent(Data.self, forKey: .userInfo)
        
        didUpdateLayout()
        update()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(identifier, forKey: .identifier)
        try container.encode(layout, forKey: .layout)
        try container.encode(rotationCenter, forKey: .rotationCenter)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(strokeColor.xColor, forKey: .strokeColor)
        try container.encode(fillColor.xColor, forKey: .fillColor)
        try container.encode(lineWidth, forKey: .lineWidth)
        try container.encode(isFinished, forKey: .isFinished)
        
        let userInfo = userInfoForEncoding()
        try container.encodeIfPresent(userInfo, forKey: .userInfo)
    }
    
    open func userInfoForEncoding() -> Data? {
        nil
    }
    
    open func applyingUserInfo(_ data: Data) {
        
    }
    
    func convert<T: CanvasObject>(to type: T.Type) -> T {
        let object = type.init()
        
        object.identifier     = identifier
        object.layout         = layout
        object.rotationCenter = rotationCenter
        object.rotation       = rotation
        object.strokeColor    = strokeColor
        object.fillColor      = fillColor
        object.lineWidth      = lineWidth
        object.isFinished     = isFinished
        object.userInfo       = userInfo
        
        if let data = userInfo {
            object.applyingUserInfo(data)
        }
        
        object.update()
        
        return object
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        do {
            let data = try JSONEncoder().encode(self)
            let object = try JSONDecoder().decode(Self.self, from: data)
            return object.convert(to: Self.self)
        } catch {
            fatalError("Copying Error: \(error)")
        }
    }
    
}

extension CanvasObject: BidirectionalCollection {
    
    public var startIndex: Int { layout.startIndex }
    
    public var endIndex: Int { layout.endIndex }
    
    public subscript(position: Int) -> [CGPoint] {
        layout[position]
    }
    
    public func index(before i: Int) -> Int {
        layout.index(before: i)
    }
    
    public func index(after i: Int) -> Int {
        layout.index(after: i)
    }
    
    public func next() -> [CGPoint]? {
        guard counter < layout.count else { return nil }
        defer { counter += 1 }
        return layout[counter]
    }
    
}
