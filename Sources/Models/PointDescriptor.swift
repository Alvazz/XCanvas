//
//  PointDescriptor.swift
//  
//
//  Created by scchn on 2021/5/5.
//

import Foundation

public enum PointDescriptor: Equatable, Codable {
    
    case indexPath(IndexPath)
    case point(CGPoint)
    
    enum CodingKeys: String, CodingKey {
        case indexPath
        case point
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let key = container.allKeys.first else {
            let desc = "Unable to decode"
            let ctx = DecodingError.Context(codingPath: container.codingPath, debugDescription: desc)
            throw DecodingError.dataCorrupted(ctx)
        }
        switch key {
        case .indexPath:
            let indexPath = try container.decode(IndexPath.self, forKey: key)
            self = .indexPath(indexPath)
        case .point:
            let point = try container.decode(CGPoint.self, forKey: key)
            self = .point(point)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .indexPath(indexPath):
            try container.encode(indexPath, forKey: .indexPath)
        case let .point(point):
            try container.encode(point, forKey: .point)
        }
    }
    
}
