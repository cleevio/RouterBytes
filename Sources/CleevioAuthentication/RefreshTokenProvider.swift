//
//  RefreshTokenProvider.swift
//  
//
//  Created by Lukáš Valenta on 13.08.2023.
//

import Foundation
import CleevioAPI

public protocol RefreshTokenProvider<APIToken> {
    /// The type of API token to be refreshed.
    associatedtype APIToken: CodableAPITokentType

    /// Asynchronously gets a refreshed access token.
    /// - Returns: A refreshed access token.
    func getRefreshedAPIToken(currentToken: APIToken) async throws -> APIToken
}

/// A simple implementation of RefreshTokenProvider that uses its provided APIService and through provided RefreshTokenAPIRouter returns refreshed APIToken
public struct APIRouterRefreshTokenProvider<
    APIToken: CodableAPITokentType,
    RefreshTokenAPIRouter: CleevioAuthentication.RefreshTokenAPIRouter,
    APIService: APIServiceType,
    HostnameProvider: CleevioAPI.HostnameProvider
>: RefreshTokenProvider where RefreshTokenAPIRouter.APIToken == APIToken {

    private let apiService: APIService
    let hostnameProvider: HostnameProvider

    public init(apiService: APIService,
                hostnameProvider: HostnameProvider,
                apiToken: APIToken.Type = APIToken.self,
                refreshTokenAPIRouter: RefreshTokenAPIRouter.Type = RefreshTokenAPIRouter.self) {
        self.apiService = apiService
        self.hostnameProvider = hostnameProvider
    }

    public func getRefreshedAPIToken(currentToken: APIToken) async throws -> APIToken {
        let router = RefreshTokenAPIRouter(previousToken: currentToken)

        let urlRequest = try router.asURLRequest(hostname: hostnameProvider.hostname(for: router)).withBearerToken(currentToken.refreshToken.description)

        let decoded: RefreshTokenAPIRouter.Response = try await apiService.getDecoded(from: try await apiService.getDataFromNetwork(for: urlRequest), decoder: router.jsonDecoder)

        return decoded.asAPIToken()
    }
}
