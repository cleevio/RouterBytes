//
//  HostnameProvider.swift
//  
//
//  Created by Lukáš Valenta on 26.05.2023.
//

import Foundation

/// A protocol that defines a type capable of providing a hostname for a given API router.
///
/// Implement this protocol to create a custom hostname provider for your API client.
public protocol HostnameProvider {
    /// Returns the hostname for the given API router.
    ///
    /// - Parameter router: The API router to get the hostname for.
    /// - Returns: The hostname for the given API router.
    func hostname(for router: some APIRouter) -> URL
}

public extension HostnameProvider {
    /// Default implementation of `hostname(for:)` for routers conforming to `HasHostname`.
    ///
    /// - Parameter router: The API router to get the hostname for.
    /// - Returns: The hostname for the given API router.
    @inlinable
    func hostname<T: APIRouter>(for router: T) -> URL where T: HasHostname {
        router.hostname
    }
}

/// A basic hostname provider that returns a fixed hostname for any given API router.
public struct BaseHostnameProvider: HostnameProvider {
    /// The fixed hostname used by this provider.
    public let hostname: URL
    
    /// Initializes a new BaseHostnameProvider with the given hostname.
    ///
    /// - Parameter hostname: The fixed hostname for the API requests.
    @inlinable
    public init(hostname: URL) {
        self.hostname = hostname
    }

    /// Returns the fixed hostname for any given API router.
    ///
    /// - Parameter router: The API router to get the hostname for.
    /// - Returns: The fixed hostname for any given API router.
    @inlinable
    public func hostname(for router: some APIRouter) -> URL {
        hostname
    }
}
