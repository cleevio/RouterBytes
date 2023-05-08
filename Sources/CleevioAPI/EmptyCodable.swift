//
//  EmptyCodable.swift
//  
//
//  Created by Lukáš Valenta on 28.04.2023.
//

import Foundation

/// A type that represents an empty `Codable` value.
///
/// `EmptyCodable` is a convenient type that can be used as a placeholder for empty or unused request/response bodies in a `Codable` format. Since `Codable` requires a type that conforms to both `Encodable` and `Decodable`, `EmptyCodable` provides an implementation that satisfies these requirements with an empty implementation.
/// It also provides a specific type for APIRouter conforming type.
///
/// Usage:
/// ```
/// struct MyRequest: Encodable {
///     var id: Int
///     var name: String
///     var payload: EmptyCodable
/// }
///
/// let request = MyRequest(id: 1, name: "Example", payload: EmptyCodable())
/// ```
public struct EmptyCodable: Codable, Sendable {
    public init() { }
}
