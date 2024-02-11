//
//  ContentType.swift
//  
//
//  Created by Lukáš Valenta on 11.02.2024.
//

import Foundation

public struct ContentType: RawRepresentable, Hashable, Codable, Sendable  {
    public let rawValue: String

    @inlinable
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let applicationJSON: ContentType = "application/json"
}

/// Enables initialization of a path using a string literal.
extension ContentType: ExpressibleByStringLiteral {
    @inlinable
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}
