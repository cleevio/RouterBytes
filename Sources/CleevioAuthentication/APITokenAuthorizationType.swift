//
//  APITokenAuthorizationType.swift
//  
//
//  Created by Lukáš Valenta on 03.06.2023.
//

import Foundation
import CleevioAPI

@available(macOS 10.15.0, *)
public protocol APITokenAuthorizationType {
    func authorizedRequest(urlRequest: URLRequest, with tokenManager: some TokenManagerType) async throws -> URLRequest
}

@available(macOS 10.15.0, *)
extension CleevioAPI.AuthorizationType: APITokenAuthorizationType {
    public func authorizedRequest(urlRequest: URLRequest, with tokenManager: some TokenManagerType) async throws -> URLRequest {
        switch self {
        case let .bearer(tokenType):
            let token: String

            switch tokenType {
            case .accessToken:
                token = try await tokenManager.getAccessToken(forceRefresh: false).description
            case .refreshToken:
                token = try await tokenManager.getRefreshToken().description
            }
            
            return urlRequest.withBearerToken(token)
        case .none:
            return urlRequest
        }
    }
}
