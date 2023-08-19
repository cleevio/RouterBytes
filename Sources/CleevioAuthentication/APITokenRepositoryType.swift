//
//  APITokenRepositoryType.swift
//  
//
//  Created by Lukáš Valenta on 02.05.2023.
//

import Foundation
import CleevioStorage

/// A type alias for a Codable APITokenType.
public typealias CodableAPITokenType = APITokenType & Codable
public typealias CodableRefreshableAPITokenType = CodableAPITokenType & RefreshableAPITokenType

/// A storage stream that holds an API token that conforms to the CodableAPITokentType protocol.
/// Generic over APITokenType
@available(macOS 12.0, *)
public typealias APITokenStorageStream<APIToken: CodableAPITokenType> = StorageStream<APIToken>

/// A protocol that defines the behavior of an API token repository.
/// Generic over APITokenType
@available(macOS 12.0, *)
public protocol APITokenRepositoryType<APIToken>: SettableAPITokenProvider {
    /// The storage stream that holds the API token.
    var apiTokenStream: APITokenStorageStream<APIToken> { get }
}

extension APITokenRepositoryType {
    public var apiToken: APIToken { get throws {
        guard let value = apiTokenStream.value else { throw NotLoggedInError() }
        return value
    } }
    public var isUserLoggedIn: Bool { apiTokenStream.value != nil }

    @inlinable
    public func setAPIToken(_ apiToken: APIToken) {
        self.apiTokenStream.store(apiToken)
        
    }

    @inlinable
    public func removeAPITokenFromStorage() {
        apiTokenStream.store(nil)
    }
}

/// A mock implementation of an API token repository.
/// Generic over APITokenType to be stored in the repository.
@available(macOS 12.0, *)
public struct APITokenRepositoryMock<APIToken: CodableAPITokenType>: APITokenRepositoryType  {    
    /// The storage stream that holds the API token.
    public let apiTokenStream: APITokenStorageStream<APIToken>

    /// Creates a new instance of the mock repository with the specified API token.
    ///
    /// - Parameter apiToken: The initial API token value to use for the repository.
    public init(apiToken: APIToken?) {
        self.apiTokenStream = .init(currentValue: apiToken)
    }
}
