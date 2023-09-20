//
//  RefreshableTokenProvider.swift
//  
//
//  Created by Lukáš Valenta on 19.08.2023.
//

import Foundation
import CleevioAPI

/// A SettableAPITokenProvider that is based on some settable token storage and refresh provider that handles the refresh
@available(macOS 10.15, *)
public actor RefreshableTokenProvider<
    APIToken: CodableAPITokenType,
    TokenStorage: SettableAPITokenProvider<APIToken>,
    RefreshProvider: CleevioAuthentication.RefreshTokenProvider<APIToken>
>: SettableAPITokenProvider {
    /// Initializes a new instance of `TokenManager`.
    ///
    /// - Parameters:
    ///   - apiService: The `APIService` to use for API requests.
    ///   - dateProvider: The `DateProviderType` to use for getting the current date.
    ///   - apiTokenRepository: The `APITokenRepositoryType` to use for storing and retrieving API tokens.
    public init(storage: TokenStorage,
                refreshProvider: RefreshProvider,
                authorizationType: AuthorizationType.Type = AuthorizationType.self,
                apiToken: APIToken.Type = APIToken.self) {
        self.refreshProvider = refreshProvider
        self.storage = storage
    }

    nonisolated
    public var isUserLoggedIn: Bool { storage.isUserLoggedIn }
    
    private var refreshingTask: Task<APIToken, Error>?
    public let storage: TokenStorage
    private let refreshProvider: RefreshProvider


    public var apiToken: APIToken { get async throws {
        try await getAPIToken(forceRefresh: false)
        
    } }

    public func setAPIToken(_ apiToken: APIToken) async throws {
        try await storage.setAPIToken(apiToken)
    }

    public func removeAPITokenFromStorage() async {
        await storage.removeAPITokenFromStorage()
    }

    public func logout() async {
        await removeAPITokenFromStorage()
    }

    public func attemptAPITokenRefresh() async throws {
        _ = try await getAPIToken(forceRefresh: true)
    }

    /// Retrieves an access token, optionally forcing a refresh.
    ///
    /// - Parameter forceRefresh: Whether or not to force a refresh of the access token.
    ///
    /// - Returns: The access token.
    ///
    /// - Throws: `NotLoggedInError` if the user is not logged in
    /// - Throws: `FailedWithUnAuthorizedError` if the refresh failed.
    private func getAPIToken(forceRefresh: Bool) async throws -> APIToken {
        if let refreshingTask {
            return try await refreshingTask.value
        }

        let apiToken = try await storage.apiToken

        guard !(try await refreshIsNeeded(forceRefresh: forceRefresh, currentToken: apiToken)) else {
            let refreshingTask = Task { [refreshProvider] in
                return try await refreshProvider.getRefreshedAPIToken(currentToken: apiToken)
            }

            self.refreshingTask = refreshingTask

            do {
                let token = try await refreshingTask.value
                try await setAPIToken(token)
                self.refreshingTask = nil
                return token
            } catch {
                self.refreshingTask = nil
                throw FailedWithUnAuthorizedError(reason: error)
            }
        }

        return apiToken
    }

    private func refreshIsNeeded(forceRefresh: Bool, currentToken: APIToken) async throws -> Bool {
        if forceRefresh { return true }
        return try await refreshProvider.tokenNeedsToBeRefreshed(currentToken: currentToken)
    }
}
