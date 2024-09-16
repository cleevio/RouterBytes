//
//  HTTPMethod.swift
//  
//
//  Created by Lukáš Valenta on 28.04.2023.
//

import Foundation

public struct HTTPMethod: Equatable, Hashable, ExpressibleByStringLiteral, Sendable {
    /// `CONNECT` method.
    public static let connect: HTTPMethod = "CONNECT"
    /// `DELETE` method.
    public static let delete: HTTPMethod = "DELETE"
    /// `GET` method.
    public static let get: HTTPMethod = "GET"
    /// `HEAD` method.
    public static let head: HTTPMethod = "HEAD"
    /// `OPTIONS` method.
    public static let options: HTTPMethod = "OPTIONS"
    /// `PATCH` method.
    public static let patch: HTTPMethod = "PATCH"
    /// `POST` method.
    public static let post: HTTPMethod = "POST"
    /// `PUT` method.
    public static let put: HTTPMethod = "PUT"
    /// `TRACE` method.
    public static let trace: HTTPMethod = "TRACE"

    public let rawValue: String

    @inlinable
    public init(stringLiteral rawValue: String) {
        self.rawValue = rawValue
    }
}
