//
//  APITokenStorageType.swift
//  
//
//  Created by Lukáš Valenta on 13.08.2023.
//

import Foundation
import CleevioStorage
import CleevioAPI

/// A protocol that defines necessary interface an APIToken storage needs to implement to work with TokenManager
public protocol APITokenProvider<APIToken> {
    /// The type of API token to be stored in the storage.
    associatedtype APIToken: CodableAPITokenType

    var apiToken: APIToken { get async throws }

    var isUserLoggedIn: Bool { get }

    func removeAPITokenFromStorage() async
    func attemptAPITokenRefresh() async throws
}

public extension APITokenProvider {
    func attemptAPITokenRefresh() async throws { }
}

public protocol SettableAPITokenProvider<APIToken>: APITokenProvider {
    func setAPIToken(_ apiToken: APIToken) async throws
}
