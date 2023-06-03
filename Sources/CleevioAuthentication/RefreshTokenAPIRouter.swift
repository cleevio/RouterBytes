//
//  RefreshTokenAPIRouter.swift
//  
//
//  Created by Lukáš Valenta on 02.05.2023.
//

import Foundation
import CleevioAPI

/**
A protocol for API routers that handle refreshing authentication tokens.

The `RefreshTokenAPIRouter` protocol extends the `APIRouter` protocol and requires the router to have a `Response` type that conforms to the `CodableAPITokentype` protocol. Additionally, it requires the router to have an initializer with no arguments.
*/
public protocol RefreshTokenAPIRouter: APIRouter where Response: TokenAPIRouterResponse {
    associatedtype APIToken: APITokenType = BaseAPIToken

    init(previousToken: APIToken)
}

public protocol TokenAPIRouterResponse: Codable {
    associatedtype APIToken: APITokenType = BaseAPIToken

    func asAPIToken() -> APIToken
}
