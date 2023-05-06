//
//  TokenAPIService.swift
//  
//
//  Created by Lukáš Valenta on 05.05.2023.
//

import Foundation
import CleevioAPI

/**
 `TokenAPIService` is a subclass of `APIService` that handles network requests for authenticated endpoints. It utilizes a token manager to retrieve access tokens and refresh tokens, and automatically adds the necessary bearer token header to each request.

 `TokenAPIService` is initialized with a `TokenManager` instance and a networking service that conforms to the `NetworkingServiceType` protocol.

 To use `TokenAPIService`, create an instance with the required `TokenManager` and `NetworkingServiceType` instances, and call its `getData` method with an implementation of `APIRouter` that specifies the endpoint and the required authorization type.
 
 If the request fails with a `401 Unauthorized` response, `TokenAPIService` attempts to refresh the access token and sends the request again with the refreshed token. If the refresh fails or the user is not logged in, it logs out the user and throws an error.

 This class overrides the `getSignedURLRequest` method of `APIService` to ensure the bearer token is included in the request header.

 - Note: `TokenAPIService` is designed to handle authentication, token refreshing, and retrying requests when necessary.

 - SeeAlso: `TokenManagerType`, `NetworkingServiceType`
 */
@available(macOS 12.0, *)
open class TokenAPIService<APIToken: CodableAPITokentType, AuthorizationType, TokenManager>: CleevioAPI.APIService<AuthorizationType> where TokenManager: TokenManagerType<APIToken> {
    /// The token manager used to retrieve access tokens and refresh tokens.
    public final let tokenManager: TokenManager

    /**
     Initializes a `TokenAPIService` object with a specified token manager and networking service.
     
     - Parameters:
        - tokenManager: The token manager to use for retrieving access tokens and refresh tokens.
        - networkingService: The networking service to use for network requests.
     */
    @inlinable
    public init(tokenManager: TokenManager, networkingService: NetworkingServiceType) {
        self.tokenManager = tokenManager
        super.init(networkingService: networkingService)
    }

    /**
     Sends a network request to the specified API endpoint and returns the response.
     
     This function retrieves the access token from the token manager and adds the necessary bearer token header to the request before sending it. If the request fails with a 401 Unauthorized response, it attempts to refresh the access token and sends the request again with the refreshed token. If the refresh fails or the user is not logged in, it logs out the user and throws an error.
     
     - Parameters:
        - router: The router object that defines the API endpoint and the required authorization type.
     
     - Returns: The decoded response from the API.
     
     - Throws:
        - `TokenManagerError.notLoggedIn` if the user is not logged in.
        - An error thrown by the API service if the request fails or if there is an issue with the response.
     */
    override open func getData<RouterType>(from router: RouterType) async throws -> RouterType.Response where AuthorizationType == RouterType.AuthorizationType, RouterType : APIRouter {
        do {
            return try await super.getData(from: router)
        } catch ResponseValidationError.unauthorized {
            do {
                return try await getDecoded(from: try await getSignedURLRequest(from: router, forceRefresh: true), decoder: router.jsonDecoder)
            } catch {
                await tokenManager.logout()
                throw error
            }
        } catch {
            guard let error = error as? ResponseValidationError, error == .invalidResponseCode else {
                throw error
            }
            
            return try await getDecoded(from: try await getSignedURLRequest(from: router, forceRefresh: false), decoder: router.jsonDecoder)
        }
    }

    /**
     Returns a signed URL request created by a given router with the necessary bearer token header added to it.
     
     This method creates and signs a `URLRequest` using the `asURLRequest` method of the given `APIRouter`. It then retrieves the access token from the token manager and adds the necessary bearer token header to the request before returning it.
     
     - Parameter router: The router to use for creating the request.
     
     - Returns: A signed `URLRequest` object with the necessary bearer token header added to it.
     
     - Throws: An error if the URLRequest could not be created from the APIRouter or if there was an issue retrieving the access token.
     */
    @inlinable
    open override func getSignedURLRequest<RouterType>(from router: RouterType) async throws -> URLRequest where AuthorizationType == RouterType.AuthorizationType, RouterType : APIRouter {
        try await getSignedURLRequest(from: router, forceRefresh: false)
    }

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
    open func getSignedURLRequest<RouterType>(from router: RouterType, forceRefresh: Bool) async throws -> URLRequest where AuthorizationType == RouterType.AuthorizationType, RouterType : APIRouter {
        try await super.getSignedURLRequest(from: router)
    }
}
