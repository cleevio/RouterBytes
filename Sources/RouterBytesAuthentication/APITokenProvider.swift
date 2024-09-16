//
//  APITokenStorageType.swift
//  
//
//  Created by Lukáš Valenta on 13.08.2023.
//

import Foundation
import CleevioStorage
import RouterBytes

/// A protocol that defines necessary interface an APIToken storage needs to implement to work with TokenManager
public protocol APITokenProvider<APIToken>: Sendable {
    /// The type of API token to be stored in the storage.
    associatedtype APIToken: CodableAPITokenType

    /// Asynchronously returns APIToken
    ///
    /// - Throws: `NotLoggedInError` if the user is not logged in
    var apiToken: APIToken { get async throws }

    var isUserLoggedIn: Bool { get }

    /// A function that should remove APIToken from storage -> logout the user.
    func removeAPITokenFromStorage() async

    /// APITokenProvider should attempt to refresh APIToken if it makes sense given that particular provider
    /// Default behavior is it does not do anything
    ///
    /// - Throws: error if refresh failed
    func attemptAPITokenRefresh() async throws
}

public extension APITokenProvider {
    func attemptAPITokenRefresh() async throws { }
}

public protocol SettableAPITokenProvider<APIToken>: APITokenProvider {
    func setAPIToken(_ apiToken: APIToken) async throws
}
