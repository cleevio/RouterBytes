//
//  RefreshTokenAPIRouter.swift
//  
//
//  Created by Lukáš Valenta on 02.05.2023.
//

import Foundation
import RouterBytes

/**
A protocol for API routers that handle refreshing authentication tokens.

The `RefreshTokenAPIRouter` protocol extends the `APIRouter` protocol and requires the router to have a `Response` type that conforms to the `CodableAPITokentype` protocol. Additionally, it requires the router to have an initializer with no arguments.
*/
@available(macOS 10.15, *)
public protocol RefreshTokenAPIRouter: APIRouter where Response: TokenAPIRouterResponse {
    associatedtype APIToken: RefreshableAPITokenType = BaseAPIToken where APIToken == Response.APIToken

    init(previousToken: APIToken)
}

@available(macOS 10.15, *)
public protocol TokenAPIRouterResponse: Codable {
    associatedtype APIToken: RefreshableAPITokenType = BaseAPIToken

    func asAPIToken() -> APIToken
}
