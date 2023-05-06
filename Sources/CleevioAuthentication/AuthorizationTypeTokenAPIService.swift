//
//  AuthorizationTypeTokenAPIService.swift
//  
//
//  Created by Lukáš Valenta on 06.05.2023.
//

import Foundation
import CleevioAPI

/**
 `AuthorizationTypeTokenApiService` is a subclass of `TokenAPIService` that provides specific authorization handling based on the `AuthorizationType` specified.

 `AuthorizationTypeTokenApiService` is initialized with an `APIToken` type that conforms to `CodableAPITokentType`.

 To use `AuthorizationTypeTokenApiService`, create an instance of it with the necessary `APIToken` type, token manager, and networking service, and then use it to make authenticated network requests.

 Overrides the `getSignedURLRequest` method to handle the addition of the bearer token header based on the authorization type defined in the `APIRouter`.
 */
@available(macOS 12.0, *)
open class AuthorizationTypeTokenAPIService<APIToken: CodableAPITokentType, TokenManager>: TokenAPIService<APIToken, AuthorizationType, TokenManager> where TokenManager: TokenManagerType<APIToken> {
    /**
     Returns a signed URL request created by a given router with the necessary bearer token header added to it.

     This method creates and signs a `URLRequest` using the `asURLRequest` method of the given `APIRouter`. It then retrieves the access token or refresh token from the token manager and adds the necessary bearer token header to the request before returning it.

     If `forceRefresh` is `true`, the method will attempt to retrieve a refreshed access token from the token manager before adding it to the request header.

     - Parameters:
        - router: The router to use for creating the request.
        - forceRefresh: Whether to force a refresh of the access token.

     - Returns: A signed `URLRequest` object with the necessary bearer token header added to it.

     - Throws:
        - `TokenManagerError.notLoggedIn` if the user is not logged in.
        - An error if there was an issue retrieving the access token or creating the URL request.
     */
    @inlinable
    override open func getSignedURLRequest<RouterType>(from router: RouterType, forceRefresh: Bool) async throws -> URLRequest where AuthorizationType == RouterType.AuthorizationType, RouterType : APIRouter {
        var urlRequest: URLRequest { get throws { try router.asURLRequest() } }
        switch router.authType {
        case .bearer(.accessToken):
            let accessToken = try await tokenManager.getAccessToken(forceRefresh: forceRefresh)
            return try urlRequest.withBearerToken(accessToken.description)
        case .bearer(.refreshToken):
            let refreshToken = try await tokenManager.getRefreshToken()
            return try urlRequest.withBearerToken(refreshToken.description)
        case .none:
            return try urlRequest
        }
    }
}

