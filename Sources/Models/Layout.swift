//
//  Layout.swift
//  
//
//  Created by scchn on 2021/4/23.
//

import Foundation

struct Layout: Codable {
    
    enum CodingKeys: String, CodingKey {
        case sections
    }
    
    typealias Section = [CGPoint]
    
    private(set)
    var sections: [Section]
    
    private var counter = 0
    
    init(_ sections: [Section] = []) {
        self.sections = sections
    }
    
    mutating func push(_ point: CGPoint, next: Bool = false) {
        if sections.isEmpty {
            sections.append([point])
        } else {
            if next {
                sections.append([point])
            } else {
                sections[sections.endIndex - 1].append(point)
            }
        }
    }
    
    mutating func pop() -> CGPoint? {
        guard !sections.isEmpty else { return nil }
        let last = sections[sections.endIndex - 1].removeLast()
        if sections.last?.isEmpty == true {
            sections.removeLast()
        }
        return last
    }
    
    mutating func update(_ point: CGPoint, section: Int, item: Int) {
        sections[section][item] = point
    }
    
}

extension Layout: BidirectionalCollection {
    
    var startIndex: Int { sections.startIndex }
    
    var endIndex: Int { sections.endIndex }
    
    subscript(position: Int) -> [CGPoint] {
        sections[position]
    }
    
    func index(before i: Int) -> Int {
        sections.index(before: i)
    }
    
    func index(after i: Int) -> Int {
        sections.index(after: i)
    }
    
    mutating func next() -> [CGPoint]? {
        guard counter < sections.count else { return nil }
        defer { counter += 1 }
        return sections[counter]
    }
    
}
