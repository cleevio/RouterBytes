//
//  APIRouter.swift
//  
//
//  Created by Lukáš Valenta on 28.04.2023.
//

import Foundation

public typealias APIRequestBody = any Encodable
public typealias Headers = [String: String]

/**
 A type representing a request for a remote API resource.

 ## Usage
 The `APIRouter` protocol defines properties and methods for creating and configuring an API request. The conforming type must define `Response` and `AuthorizationType` associated types to represent the expected response and the authorization mechanism used for the request, respectively.

 ### Default Values
 The `APIRouter` extension provides default values for some properties:
 - `additionalHeaders`: an empty dictionary
 - `queryItems`: an empty dictionary
 - `body`: `nil`
 - `method`: `.get`
 - `cachePolicy`: `.reloadIgnoringCacheData`
 - `headers`: A computed property that returns the default headers merged with any additional headers.
 - `Note`: To conform to APIRouter, you should implement the following properties:

    - `defaultHeaders`: The default headers for the API endpoint.
    - `hostname`: The hostname for the API endpoint.
    - `jsonDecoder`: The `JSONDecoder` to use for decoding responses.
    - `jsonEncoder`: The `JSONEncoder` to use for encoding requests.
    - `path`: The path for the API endpoint.
    - `authType`: The authorization type for the API endpoint.
 - SeeAlso: `APIRouterError`,` `HTTPMethod`, `Headers`, `APIRequestBody`
 */
public protocol APIRouter<RequestBody> {
    associatedtype Response: Decodable
    associatedtype AuthorizationType
    associatedtype RequestBody: Encodable

    // Properties to be specified within the project APIRouter protocol
    /// The default headers for the API endpoint.
    var defaultHeaders: Headers { get }
    /// The hostname for the API endpoint.
    var hostname: URL { get }
    /// The JSON decoder to use for decoding responses.
    var jsonDecoder: JSONDecoder { get }
    /// The JSON encoder to use for encoding requests.
    var jsonEncoder: JSONEncoder { get }
    
    /// The path for the API endpoint.
    var path: String { get }
    /// Additional headers to be added to the request headers for the API endpoint.
    /// Empty dictionary if not specified
    var additionalHeaders: Headers { get }
    /// Query items to be added to the URL for the API endpoint.
    /// Empty dictionary if not specified
    var queryItems: [String: String] { get }
    /// The HTTP method for the API endpoint.
    /// .get by default
    var method: HTTPMethod { get }
    /// The body of the API request.
    /// Nil by default
    var body: RequestBody? { get }
    /// The authorization type for the API endpoint.
    var authType: AuthorizationType { get }
    /// The cache policy for the API request. Default: .get
    var cachePolicy: URLRequest.CachePolicy { get }
}

public extension APIRouter {
    var additionalHeaders: [String: String] { [:] }
    var queryItems: [String: String] { [:] }
    var method: HTTPMethod { .get }
    var cachePolicy: URLRequest.CachePolicy { .reloadIgnoringCacheData }

    /// Computed property that merges defaultHeaders and additionalHeaders
    var headers: Headers {
        defaultHeaders.merging(additionalHeaders) { _, additionalHeaders in additionalHeaders }
    }

    /// Function that converts APIRouter instance to a URL
    func asURL() throws -> URL {
        guard var components = URLComponents(url: hostname, resolvingAgainstBaseURL: false) else {
            throw APIRouterError.invalidHostname
        }

        components.path = path

        if !queryItems.isEmpty {
            components.queryItems = queryItems.map(URLQueryItem.init)
        }

        guard let url = components.url else {
            throw APIRouterError.invalidURL(components: components)
        }

        return url
    }

    /// Converts the APIRequest to a `URLRequest`.
    func asURLRequest() throws -> URLRequest {
        var urlRequest = try URLRequest(url: asURL())

        urlRequest.httpMethod = method.rawValue

        for header in headers {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
        }

        if let body = body {
            urlRequest.httpBody = try jsonEncoder.encode(body)
        }

        return urlRequest
    }
}

public extension APIRouter<EmptyCodable> {
    var body: RequestBody? { nil }
}
