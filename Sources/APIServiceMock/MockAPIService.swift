//
//  MockAPIService.swift
//
//
//  Created by Lukáš Valenta on 12.02.2024.
//

import Foundation
import CleevioAPI

public final class MockAPIService: CleevioAPI.APIRouterServiceType {
    public typealias AuthorizationType = CleevioAPI.AuthorizationType
    
    private var responsesOnRouter: [ObjectIdentifier: (any APIRouter) async throws -> (Any)] = [:]
    private var urlRequstsOnUnAuthorizedRouter: [ObjectIdentifier: (any APIRouter) async throws -> (URLRequest)] = [:]
    private var urlRequestProviders: [ObjectIdentifier: (Any) async throws -> URLRequest] = [:]
    private var decodedProviders: [ObjectIdentifier: (Any) async throws -> Any] = [:]
    private var dataFromNetworkProviders: [URLRequest: (URLRequest) async throws -> Data] = [:]
    private var dataProviders: [ObjectIdentifier: (Any) async throws -> Data] = [:]

    public init() { }

    public func registerURLRequestResponseOnUnAuthorizedRouter<Router: CleevioAPI.APIRouter>(router: Router, response: @escaping (Router) -> (URLRequest)) {
        urlRequstsOnUnAuthorizedRouter[ObjectIdentifier(Router.self)] = { router in
            response(router as! Router)
        }
    }

    public func registerDataProvider<Router: CleevioAPI.APIRouter>(
        for routerType: Router.Type,
        dataProvider: @escaping (Router) throws -> Data
    ) {
        dataProviders[ObjectIdentifier(routerType)] = { router in
            guard let router = router as? Router else {
                fatalError("URL Request provider not registered")
            }
            return try dataProvider(router)
        }
    }
    
    public func registerURLRequestProvider<Router: CleevioAPI.APIRouter>(
        for routerType: Router.Type,
        urlRequestProvider: @escaping (Router) throws -> URLRequest
    ) {
        urlRequestProviders[ObjectIdentifier(routerType)] = { router in
            guard let router = router as? Router else {
                fatalError("URL Request provider not registered")
            }
            return try urlRequestProvider(router)
        }
    }
    
    public func registerDecodedProvider<Router: CleevioAPI.APIRouter, DecodedType>(
        for routerType: Router.Type,
        decodedProvider: @escaping (Router) throws -> DecodedType
    ) {
        decodedProviders[ObjectIdentifier(routerType)] = { router in
            guard let router = router as? Router else {
                fatalError("URL Request provider not registered")
            }
            return try decodedProvider(router)
        }
    }
    
    public func registerDataFromNetworkProvider(
        for request: URLRequest,
        dataProvider: @escaping (URLRequest) throws -> Data
    ) {
        dataFromNetworkProviders[request] = dataProvider
    }


    private func getResponseOnRouter<APIRouter: CleevioAPI.APIRouter>(router: APIRouter) async throws -> APIRouter.Response {
        guard let response = responsesOnRouter[ObjectIdentifier(APIRouter.self)] else {
            fatalError("Response not registered")
        }

        return try await response(router) as! APIRouter.Response
    }
    
    public func getResponse<RouterType>(from router: RouterType) async throws -> RouterType.Response where RouterType : CleevioAPI.APIRouter, AuthorizationType == RouterType.AuthorizationType, RouterType.Response : Decodable {
        try await getResponseOnRouter(router: router.self)
    }
    
    public func getResponse<RouterType>(from router: RouterType) async throws where RouterType : CleevioAPI.APIRouter, AuthorizationType == RouterType.AuthorizationType, RouterType.Response == () {
        try await getResponseOnRouter(router: router)
    }
    
    public func getURLRequest<RouterType>(from router: RouterType) async throws -> URLRequest where RouterType : CleevioAPI.APIRouter, AuthorizationType == RouterType.AuthorizationType {
        guard let urlRequestProvider = urlRequestProviders[ObjectIdentifier(RouterType.self)] else {
            fatalError("DataProvider not registered")
        }
        return try await urlRequestProvider(router)
    }
    
    public func getURLRequestOnUnAuthorizedError<RouterType>(from router: RouterType) async throws -> URLRequest where RouterType : CleevioAPI.APIRouter, AuthorizationType == RouterType.AuthorizationType {
        guard let response = urlRequstsOnUnAuthorizedRouter[ObjectIdentifier(RouterType.self)] else {
            fatalError("Response not registered")
        }

        return try await response(router)
    }
    
    public func getData<RouterType>(for router: RouterType) async throws -> Data where RouterType : APIRouter, AuthorizationType == RouterType.AuthorizationType {
        guard let dataProvider = dataProviders[ObjectIdentifier(RouterType.self)] else {
            fatalError("DataFromNetwork provider not registered")
        }

        return try await dataProvider(router)
    }
    
    public func getDataFromNetwork(for request: URLRequest) async throws -> Data {
        guard let dataFromNetworkProvider = dataFromNetworkProviders[request] else {
            fatalError("DataFromNetwork provider not registered")
        }
        return try await dataFromNetworkProvider(request)
    }

    public func getDecoded<T>(from data: Data, decode: (T.Type, Data) throws -> T) async throws -> T where T : Decodable {
        try decode(T.self, data)
    }
}

