//
//  TokenManager.swift
//  
//
//  Created by Lukáš Valenta on 02.05.2023.
//

import CleevioAPI
import Foundation
import CleevioStorage

public struct NotLoggedInError: Error, Hashable { public init() { } }

public typealias TokenManager = TokenProviderWrappedURLRequestProvider

public struct TokenProviderWrappedURLRequestProvider<
    AuthorizationType: APITokenAuthorizationType,
    HostnameProvider: CleevioAPI.HostnameProvider,
    APITokenProvider: CleevioAuthentication.APITokenProvider
>: URLRequestProvider {
    public let hostnameProvider: HostnameProvider
    public let tokenProvider: APITokenProvider

    public init(hostnameProvider: HostnameProvider, tokenProvider: APITokenProvider, authorizationType: AuthorizationType.Type = AuthorizationType.self) {
        self.hostnameProvider = hostnameProvider
        self.tokenProvider = tokenProvider
    }

    public func getURLRequest<RouterType>(from router: RouterType) async throws -> URLRequest where RouterType : CleevioAPI.APIRouter, AuthorizationType == RouterType.AuthorizationType {
        var urlRequest: URLRequest { get throws { try router.asURLRequest(hostname: hostnameProvider.hostname(for: router)) } }

        return try await router.authType.authorizedRequest(urlRequest: try urlRequest, with: tokenProvider)
    }

    public func getURLRequestOnUnAuthorizedError<RouterType>(from router: RouterType) async throws -> URLRequest where RouterType : APIRouter, AuthorizationType == RouterType.AuthorizationType {
        try await tokenProvider.attemptAPITokenRefresh()
        return try await getURLRequest(from: router)
    }
}
