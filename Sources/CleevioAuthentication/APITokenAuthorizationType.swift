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
    func authorizedRequest(urlRequest: URLRequest, with provider: some APITokenProvider) async throws -> URLRequest
}

@available(macOS 10.15.0, *)
extension CleevioAPI.AuthorizationType: APITokenAuthorizationType {
    public func authorizedRequest(urlRequest: URLRequest, with provider: some APITokenProvider) async throws -> URLRequest {
        switch self {
        case let .bearer(tokenType):
            let apiToken = try await provider.apiToken
            let token: String

            switch tokenType {
            case .accessToken:
                token = apiToken.accessToken.description
            case .refreshToken:
                if let apiToken = apiToken as? (any RefreshableAPITokenType) {
                    token = apiToken.refreshToken.description
                } else {
                    assertionFailure("APIToken is not refreshable") // TODO: Find out a typesafe way if possible
                    token = ""
                }
            }
            
            return urlRequest.withBearerToken(token)
        case .none:
            return urlRequest
        }
    }
}
