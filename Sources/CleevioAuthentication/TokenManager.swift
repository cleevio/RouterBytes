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

    func setAPIToken(_ apiToken: APIToken) async throws


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
    RefreshTokenAPIRouterType: RefreshTokenAPIRouter,
    DateProvider: DateProviderType,
    HostnameProviderType: HostnameProvider,
    TokenRepository: APITokenRepositoryType<APIToken>
>: TokenManagerType where APIToken == RefreshTokenAPIRouterType.APIToken {
    private var refreshingTask: Task<APIToken, Error>?
    private let apiService: APIService<AuthorizationType>
    @usableFromInline
    let hostnameProvider: HostnameProviderType
    private let dateProvider: DateProvider
    public let apiTokenRepository: TokenRepository

    /// Initializes a new instance of `TokenManager`.
    ///
    /// - Parameters:
    ///   - apiService: The `APIService` to use for API requests.
    ///   - dateProvider: The `DateProviderType` to use for getting the current date.
    ///   - apiTokenRepository: The `APITokenRepositoryType` to use for storing and retrieving API tokens.
    public init(apiService: APIService<AuthorizationType>,
                dateProvider: DateProvider = CleevioAuthentication.DateProvider(),
                apiTokenRepository: TokenRepository,
                hostnameProvider: HostnameProviderType) {
        self.apiService = apiService
        self.dateProvider = dateProvider
        self.apiTokenRepository = apiTokenRepository
        self.hostnameProvider = hostnameProvider
    }

    nonisolated public var isUserLoggedIn: Bool {
        apiTokenRepository.apiToken.value != nil
    }

    public func checkLoggedIn() throws {
        guard isUserLoggedIn else { throw TokenManagerError.notLoggedIn }
    }

    /// The currently stored API token.
    @usableFromInline
    nonisolated var apiToken: APIToken {
        get throws {
            guard let apiToken = apiTokenRepository.apiToken.value else { throw TokenManagerError.notLoggedIn }

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

    @inlinable
    public func setAPIToken(_ apiToken: APIToken) async throws {
        apiTokenRepository.apiToken.store(apiToken)
    }
    
    @inlinable
    public func logout() async {
        apiTokenRepository.apiToken.store(nil)
    }

    /// Asynchronously gets a refreshed access token.
     /// - Returns: A refreshed access token.
    private func getRefreshedAccessToken() async throws -> APIToken.AccessToken {
        do {
            let refreshingTask = refreshTokenTask()
            self.refreshingTask = refreshingTask

            defer { self.refreshingTask = nil }

            let apiToken = try await refreshingTask.value

            apiTokenRepository.apiToken.store(apiToken)

            return apiToken.accessToken
        } catch {
            self.refreshingTask = nil
            throw error
        }
    }

    /// Creates a task to refresh token
    private func refreshTokenTask() -> Task<APIToken, Error> {
        Task {
            guard let previousToken = apiTokenRepository.apiToken.value else { throw TokenManagerError.notLoggedIn }

            let router = RefreshTokenAPIRouterType(previousToken: previousToken)

            let urlRequest = try router.asURLRequest(hostname: hostnameProvider.hostname(for: router)).withBearerToken(previousToken.accessToken.description)

            return try await apiService.getDecoded(from: try await apiService.getDataFromNetwork(for: urlRequest), decoder: router.jsonDecoder)
        }
    }
}

@available(macOS 12.0, *)
extension TokenManager: URLRequestProvider {
    public func getURLRequest<RouterType>(from router: RouterType) async throws -> URLRequest where RouterType : CleevioAPI.APIRouter, AuthorizationType == RouterType.AuthorizationType {
        var urlRequest: URLRequest { get throws { try router.asURLRequest(hostname: hostnameProvider.hostname(for: router)) } }

        return try await router.authType.authorize(urlRequest: try urlRequest, with: self)
    }
    
    @inlinable
    public func getURLRequestOnUnAuthorizedError<RouterType>(from router: RouterType) async throws -> URLRequest where RouterType : APIRouter, AuthorizationType == RouterType.AuthorizationType {
        _ = try await getAccessToken(forceRefresh: true)

        return try await getURLRequest(from: router)
    }
}
