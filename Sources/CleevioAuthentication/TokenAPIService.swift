//
//  TokenAPIService.swift
//  
//
//  Created by Lukáš Valenta on 05.05.2023.
//

import Foundation
import CleevioAPI

/**
 `TokenAPIService` is a subclass of `APIService` that handles network requests for authenticated endpoints. It uses a token manager to retrieve access tokens and refresh tokens, and then adds the necessary bearer token header to the request before sending it.

 `TokenAPIService` is initialized with a `TokenManager` instance and a networking service that conforms to the `NetworkingServiceType` protocol.

 To use `TokenAPIService`, create an instance of it with the necessary `TokenManager` and `NetworkingServiceType` instances, and then call its `getData` method with an implementation of `APIRouter` that specifies the endpoint and the required authorization type.

 Overrides `getSignedURLRequest` method of `APIService` to add the bearer token to the request header.
 */
@available(macOS 12.0, *)
open class TokenAPIService<APIToken: CodableAPITokentType>: CleevioAPI.APIService<AuthorizationType> {
    public typealias TokenManager = CleevioAuthentication.TokenManagerType<APIToken>

    /// The token manager used to retrieve access tokens and refresh tokens.
    public final let tokenManager: any TokenManager

    /**
     Initializes a `TokenAPIService` object with a specified token manager and networking service.
     
     - Parameters:
        - tokenManager: The token manager to use for retrieving access tokens and refresh tokens.
        - networkingService: The networking service to use for network requests.
     */
    @inlinable
    public init(tokenManager: any TokenManager, networkingService: NetworkingServiceType) {
        self.tokenManager = tokenManager
        super.init(networkingService: networkingService)
    }

    /**
     Returns a signed URL request created by a given router with the necessary bearer token header added to it.
     
     This method creates and signs a `URLRequest` using the `asURLRequest` method of the given `APIRouter`. It then retrieves the access token or refresh token from the token manager and adds the necessary bearer token header to the request before returning it.

     `RouterType.AuthorizationType` must match the `AuthorizationType`
     
     - Parameter router: The router to use for creating the request.
     - Returns: A signed `URLRequest` object with the necessary bearer token header added to it.
     - Throws: An error if the URLRequest could not be created from APIRouter.
     */
    @inlinable
    override open func getSignedURLRequest<RouterType>(from router: RouterType) async throws -> URLRequest where AuthorizationType == RouterType.AuthorizationType, RouterType : APIRouter {
        switch router.authType {
        case .bearer(.accessToken):
            let accessToken = try await tokenManager.getAccessToken(forceRefresh: false)
            return try await super.getSignedURLRequest(from: router).withBearerToken(accessToken.description)
        case .bearer(.refreshToken):
            let refreshToken = try await tokenManager.getRefreshToken()
            return try await super.getSignedURLRequest(from: router).withBearerToken(refreshToken.description)
        case .none:
            return try await super.getSignedURLRequest(from: router)
        }
    }
}
