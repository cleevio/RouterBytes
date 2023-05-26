//
//  APIRouter.swift
//  
//
//  Created by Lukáš Valenta on 28.04.2023.
//

import Foundation

public typealias Headers = [String: String]

/**
 A type representing a request for a remote API resource.

 The `APIRouter` protocol defines properties and methods for creating and configuring an API request. The conforming type must define `Response`, `AuthorizationType`, and `RequestBody` associated types to represent the expected response, the authorization mechanism used for the request, and the request body type, respectively.

 ## Usage

 ### Default Values
 The `APIRouter` extension provides default values for some properties:
 - `additionalHeaders`: an empty dictionary
 - `queryItems`: an empty dictionary
 - `body`: `nil`
 - `method`: `.get`
 - `cachePolicy`: `.reloadIgnoringCacheData`
 - `headers`: A computed property that returns the default headers merged with any additional headers.
 
 ### Required Properties
 To conform to `APIRouter`, you should implement the following properties:

    - `defaultHeaders`: The default headers for the API endpoint.
    - `hostname`: The hostname for the API endpoint.
    - `jsonDecoder`: The `JSONDecoder` to use for decoding responses.
    - `jsonEncoder`: The `JSONEncoder` to use for encoding requests.
    - `path`: The path for the API endpoint.
    - `authType`: The authorization type for the API endpoint.

 - SeeAlso: `APIRouterError`, `HTTPMethod`, `Headers`
 */
public protocol APIRouter<RequestBody>: Sendable {
    associatedtype Response
    associatedtype AuthorizationType = CleevioAPI.AuthorizationType
    associatedtype RequestBody: Sendable = Void

    // Properties to be specified within the project APIRouter protocol
    /// The default headers for the API endpoint.
    var defaultHeaders: Headers { get }
    /// The hostname for the API endpoint.
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

    /// Converts the `RequestBody` to a `Data` object.
    /// Returns `nil` if there is no request body.
    func encodedBody() throws -> Data?
}

public extension APIRouter {
    var additionalHeaders: [String: String] { [:] }
    var queryItems: [String: String] { [:] }
    var method: HTTPMethod { .get }
    var cachePolicy: URLRequest.CachePolicy { .reloadIgnoringCacheData }

    /// Computed property that merges defaultHeaders and additionalHeaders
    @inlinable
    var headers: Headers {
        defaultHeaders.merging(additionalHeaders) { _, additionalHeaders in additionalHeaders }
    }

    /// Function that converts APIRouter instance to a URL
    /// - Parameter hostname: The base URL for the API endpoint.
    func asURL(hostname: URL) throws -> URL {
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
    /// - Parameter hostname: The base URL for the API endpoint.
    func asURLRequest(hostname: URL) throws -> URLRequest {
        var urlRequest = try URLRequest(url: asURL(hostname: hostname))

        urlRequest.httpMethod = method.rawValue

        for header in headers {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
        }

        urlRequest.httpBody = try encodedBody()

        return urlRequest
    }
}

public extension APIRouter where RequestBody: Encodable {
    @inlinable
    func encodedBody() throws -> Data? {
        guard let body else { return nil }

        return try jsonEncoder.encode(body)
    }
}

public extension APIRouter where RequestBody == Void {
    @inlinable
    var body: RequestBody? {
        nil
    }

    @inlinable
    func encodedBody() throws -> Data? {
        nil
    }
}

public protocol HasHostname {
    /// The base URL for the API endpoint.

    var hostname: URL { get }
}

public extension APIRouter where Self: HasHostname {
    /// Function that converts APIRouter instance to a URL using the `hostname` property.
    func asURL() throws -> URL {
        try asURL(hostname: hostname)
    }
    
    /// Converts the APIRequest to a `URLRequest` using the `hostname` property.
    func asURLRequest() throws -> URLRequest {
        try asURLRequest(hostname: hostname)
    }
}
