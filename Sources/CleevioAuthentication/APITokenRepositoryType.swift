//
//  APITokenRepositoryType.swift
//  
//
//  Created by Lukáš Valenta on 02.05.2023.
//

import Foundation
import CleevioStorage

/// A type alias for a Codable APITokenType.
public typealias CodableAPITokentType = APITokenType & Decodable

/// A storage stream that holds an API token that conforms to the CodableAPITokentType protocol.
/// Generic over APITokenType
@available(macOS 12.0, *)
public typealias APITokenStorageStream<APIToken: CodableAPITokentType> = StorageStream<APIToken>

/// A protocol that defines the behavior of an API token repository.
/// Generic over APITokenType
@available(macOS 12.0, *)
public protocol APITokenRepositoryType<APIToken> {
    
    /// The type of API token to be stored in the repository.
    associatedtype APIToken: CodableAPITokentType
    
    /// The storage stream that holds the API token.
    var apiToken: APITokenStorageStream<APIToken> { get }
}

/// A mock implementation of an API token repository.
/// Generic over APITokenType to be stored in the repository.
@available(macOS 12.0, *)
public struct APITokenRepositoryMock<APIToken: CodableAPITokentType>: APITokenRepositoryType {
    
    /// The storage stream that holds the API token.
    public let apiToken: APITokenStorageStream<APIToken>

    /// Creates a new instance of the mock repository with the specified API token.
    ///
    /// - Parameter apiToken: The initial API token value to use for the repository.
    public init(apiToken: APIToken?) {
        self.apiToken = .init(currentValue: apiToken)
    }
}
