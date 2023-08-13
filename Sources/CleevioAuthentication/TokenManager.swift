//
//  TokenManager.swift
//  
//
//  Created by Lukáš Valenta on 02.05.2023.
//

import CleevioAPI
import Foundation
import CleevioStorage

/// An enumeration of errors that can be thrown by `TokenManager`.
public enum TokenManagerError: Error {
    /// Thrown when the user is not logged in.
    case notLoggedIn
}

/// A protocol defining the interface for a token manager.
///
/// APIToken must conform to `CodableAPITokentType`.
@available(macOS 10.15.0, *)
public protocol TokenManagerType<APIToken>: AnyObject {
    associatedtype APIToken: CodableAPITokentType

    var isUserLoggedIn: Bool { get }

    /// Retrieves an access token, optionally forcing a refresh.
    ///
    /// - Parameter forceRefresh: Whether or not to force a refresh of the access token.
    ///
    /// - Returns: The access token.
    ///
    /// - Throws: `TokenManagerError.notLoggedIn` if the user is not logged in, or an error thrown by the API service.
    func getAccessToken(forceRefresh: Bool) async throws -> APIToken.AccessToken

    /// Retrieves the refresh token.
    ///
    /// - Returns: The refresh token.
    ///
    /// - Throws: `TokenManagerError.notLoggedIn` if the user is not logged in, or an error thrown by the API service.
    func getRefreshToken() async throws -> APIToken.RefreshToken

    func checkLoggedIn() async throws

    /// Logs out the user by clearing the stored API token.
    ///
    /// This function removes the currently stored API token from the token manager, effectively logging out the user.
    ///
    /// - Note: After calling this function, any subsequent API requests will likely result in a 403 Forbidden response.
    func logout() async
}

/// A token manager that handles the retrieval and refreshing of API tokens.
@available(macOS 12.0, *)
public final actor TokenManager<
    AuthorizationType: APITokenAuthorizationType,
    APIToken: CodableAPITokentType,
    DateProvider: DateProviderType,
    HostnameProviderType: HostnameProvider,
    TokenStorage: APITokenStorageType<APIToken>,
    RefreshProvider: CleevioAuthentication.RefreshTokenProvider<APIToken>
>: TokenManagerType {
    
    private var refreshingTask: Task<APIToken, Error>?
    @usableFromInline
    let hostnameProvider: HostnameProviderType
    private let dateProvider: DateProvider
    private let refreshProvider: RefreshProvider
    public let storage: TokenStorage

    /// Initializes a new instance of `TokenManager`.
    ///
    /// - Parameters:
    ///   - apiService: The `APIService` to use for API requests.
    ///   - dateProvider: The `DateProviderType` to use for getting the current date.
    ///   - apiTokenRepository: The `APITokenRepositoryType` to use for storing and retrieving API tokens.
    public init(storage: TokenStorage,
                refreshProvider: RefreshProvider,
                hostnameProvider: HostnameProviderType,
                dateProvider: DateProvider = CleevioAuthentication.DateProvider(),
                authorizationType: AuthorizationType.Type = AuthorizationType.self,
                apiToken: APIToken.Type = APIToken.self) {
        self.refreshProvider = refreshProvider
        self.dateProvider = dateProvider
        self.storage = storage
        self.hostnameProvider = hostnameProvider
    }

    nonisolated public var isUserLoggedIn: Bool {
        storage.isUserLoggedIn
    }

    public func checkLoggedIn() throws {
        guard isUserLoggedIn else { throw TokenManagerError.notLoggedIn }
    }

    /// The currently stored API token.
    @usableFromInline
    nonisolated var apiToken: APIToken {
        get throws {
            guard let apiToken = storage.apiToken else { throw TokenManagerError.notLoggedIn }

            return apiToken
        }
    }

    /// Retrieves an access token, optionally forcing a refresh.
    ///
    /// - Parameter forceRefresh: Whether or not to force a refresh of the access token.
    ///
    /// - Returns: The access token.
    ///
    /// - Throws: `TokenManagerError.notLoggedIn` if the user is not logged in, or an error thrown by the API service.
    public func getAccessToken(forceRefresh: Bool) async throws -> APIToken.AccessToken {
        if let refreshingTask {
            return try await refreshingTask.value.accessToken
        }

        let apiToken = try self.apiToken

        let refreshIsNeeded = forceRefresh || apiToken.needsToBeRefreshed(currentDate: dateProvider.currentDate())

        guard !refreshIsNeeded else { return try await getRefreshedAccessToken() }

        return apiToken.accessToken
    }

    /// Retrieves the refresh token.
    ///
    /// - Returns: The refresh token.
    ///
    /// - Throws: `TokenManagerError.notLoggedIn` if the user is not logged in, or an error thrown by the API service.
    @inlinable
    public func getRefreshToken() throws -> APIToken.RefreshToken {
        try apiToken.refreshToken
    }
    
    public func logout() async {
        await storage.removeAPITokenFromStorage()
    }

    /// Asynchronously gets a refreshed access token.
     /// - Returns: A refreshed access token.
    private func getRefreshedAccessToken() async throws -> APIToken.AccessToken {
        do {
            let currentToken = try apiToken
            let refreshingTask = Task { [refreshProvider] in
                try await refreshProvider.getRefreshedAPIToken(currentToken: currentToken)
            }
            self.refreshingTask = refreshingTask

            defer { self.refreshingTask = nil }

            let apiToken = try await refreshingTask.value

            try await storage.storeAPIToken(apiToken)

            return apiToken.accessToken
        } catch {
            self.refreshingTask = nil
            throw FailedWithUnAuthorizedError(reason: error)
        }
    }
}

extension TokenManager {
    @inlinable
    public func setAPIToken(_ apiToken: APIToken) async throws {
        try await storage.storeAPIToken(apiToken)
    }
}

@available(macOS 12.0, *)
extension TokenManager: CleevioAPI.URLRequestProvider {
    public func getURLRequest<RouterType>(from router: RouterType) async throws -> URLRequest where RouterType : CleevioAPI.APIRouter, AuthorizationType == RouterType.AuthorizationType {
        var urlRequest: URLRequest { get throws { try router.asURLRequest(hostname: hostnameProvider.hostname(for: router)) } }

        return try await router.authType.authorizedRequest(urlRequest: try urlRequest, with: self)
    }
    
    @inlinable
    public func getURLRequestOnUnAuthorizedError<RouterType>(from router: RouterType) async throws -> URLRequest where RouterType : APIRouter, AuthorizationType == RouterType.AuthorizationType {
        _ = try await getAccessToken(forceRefresh: true)

        return try await getURLRequest(from: router)
    }
}
