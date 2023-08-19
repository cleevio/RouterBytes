//
//  APIToken.swift
//  
//
//  Created by Lukáš Valenta on 02.05.2023.
//

import Foundation

/// A protocol that defines the behavior of an API token.
public protocol APITokenType: Sendable {
    
    /// The type used to represent the access token.
    associatedtype AccessToken: CustomStringConvertible & Sendable = String

    /// The current access token.
    var accessToken: AccessToken { get }
}

extension String: APITokenType {
    public var accessToken: String { self }
}

public protocol RefreshableAPITokenType: APITokenType {
    /// The type used to represent the refresh token.
    associatedtype RefreshToken: CustomStringConvertible & Sendable = String

    /// The refresh token.
    var refreshToken: RefreshToken { get }

    /// Returns a Boolean value indicating whether the token needs to be refreshed.
    ///
    /// - Parameters:
    ///   - currentDate: The current date.
    ///   - maximumTimeUntilExpiration: The maximum time interval until the token expires.
    ///
    /// - Returns: `true` if the token needs to be refreshed; otherwise, `false`.
    func needsToBeRefreshed(currentDate: Date, maximumTimeUntilExpiration: TimeInterval) -> Bool
}

public extension RefreshableAPITokenType {
    
    /// Returns a Boolean value indicating whether the token needs to be refreshed, using a default time interval of 300 seconds.
    ///
    /// - Parameter currentDate: The current date.
    ///
    /// - Returns: `true` if the token needs to be refreshed; otherwise, `false`.
    @inlinable
    func needsToBeRefreshed(currentDate: Date) -> Bool {
        needsToBeRefreshed(currentDate: currentDate, maximumTimeUntilExpiration: 300)
    }
}

/// A basic implementation of APITokenType.
///
/// This struct represents an API token with an access token, a refresh token, and an expiration date. It conforms to the APITokenType protocol and provides a default implementation for the `needsToBeRefreshed` method.
///
/// - Note: This struct does not conform to Codable protocol to allow for more flexibility in projects that require this struct to be codable.
@available(macOS 10.15, *)
public struct BaseAPIToken: RefreshableAPITokenType, Equatable {
    /// The access token.
    public let accessToken: String
    
    /// The refresh token.
    public let refreshToken: String
    
    /// The expiration date of the token.
    public let expiration: Date

    /// Creates a new instance of `BaseAPIToken`.
    ///
    /// - Parameters:
    ///   - accessToken: The access token string.
    ///   - refreshToken: The refresh token string.
    ///   - expiration: The expiration date of the token.
    @inlinable
    public init(accessToken: String, refreshToken: String, expiration: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiration = expiration
    }

    /// Returns a Boolean value indicating whether the token needs to be refreshed.
    ///
    /// - Parameters:
    ///   - currentDate: The current date.
    ///   - maximumTimeUntilExpiration: The maximum time interval until the token expires.
    ///
    /// - Returns: `true` if the token needs to be refreshed; otherwise, `false`.
    @inlinable
    public func needsToBeRefreshed(currentDate: Date, maximumTimeUntilExpiration: TimeInterval) -> Bool {
        expiration < currentDate.advanced(by: maximumTimeUntilExpiration)
    }
}
