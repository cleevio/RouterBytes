//
//  APIService.swift
//  
//
//  Created by Lukáš Valenta on 30.04.2023.
//

import Foundation

/**
 `APIService` is a class responsible for making network requests and decoding responses. It uses an implementation of the `NetworkingServiceType` protocol to perform the network requests and an implementation of the `URLRequestProvider` protocol to create URL requests for the network requests.
 
 To use `APIService`, subclass it and override its methods as needed. The most commonly used method is `getResponse`, which fetches data from the network. You pass an implementation of the `APIRouter` to `getResponse`, and it returns the decoded fetched data.
 
 `APIService` supports retry functionality in the `getData` method. If the network request fails due to an invalid response code or a timeout error, it will retry the request once. This behavior helps improve the reliability of data retrieval.
 
 The class also provides an optional `APIServiceEventDelegate` that can be used to receive events from the `APIService` object, such as progress updates and response decoding notifications. If the network request fails with an unauthorized error, it will attempt to fetch the data again using the `getSignedURLRequestOnUnAuthorizedError(from:)` method, and notify the event delegate if the second attempt also fails.
 
 The generic `AuthorizationType` represents the type of authorization used by the network requests. It is specified when creating an instance of `APIService`.
 
 By default, `APIService` uses `URLSession.shared` as the networking service.
 
 - Example usage:
 ```
 let networkingService = YourNetworkingService()
 let apiService = APIService<YourAuthorizationType>(networkingService: networkingService)
 
 let router = YourAPIRouter()
 do {
    let responseData: YourResponseDataType = try await apiService.getResponse(from: router)
    // Handle the decoded response data
 } catch {
    // Handle the error
 }
 ```
 */
@available(macOS 12.0, *)
open class APIService<AuthorizationType>: @unchecked Sendable {
    /// The networking service used to perform network requests.
    public final let networkingService: NetworkingServiceType
    
    /// An optional delegate that can be used to receive events from the `APIService` object.
    public final let eventDelegate: APIServiceEventDelegate?
    
    public final let urlRequestProvider: any URLRequestProvider<AuthorizationType>
    
    /**
     Initializes an `APIService` object with specified networking service, URL request provider, and an optional event delegate.
     
     - Parameter networkingService: The networking service to use for network requests. Defaults to `URLSession.shared`.
     - Parameter urlRequestProvider: The URL request provider to create URL requests for the network requests.
     - Parameter eventDelegate: An optional event delegate to handle events related to the network requests. Defaults to `nil`.
     */
    @inlinable
    public init(networkingService: NetworkingServiceType = URLSession.shared,
                urlRequestProvider: any URLRequestProvider<AuthorizationType>,
                eventDelegate: APIServiceEventDelegate? = nil) {
        self.networkingService = networkingService
        self.eventDelegate = eventDelegate
        self.urlRequestProvider = urlRequestProvider
    }

    /**
     Fetches and decodes data from the network using a given `URLRequest`.
     
     This method fetches the data from the network using the given `URLRequest`. It also decodes the data using the given `JSONDecoder` and reports the progress of the request to the `eventDelegate` if it is set.
     
     - Parameters:
     - request: The `URLRequest` to use for fetching the data.
     - decoder: The `JSONDecoder` to use for decoding the data.
     - Returns: A decoded response object of type `T`.
     - Throws: An error if the network request or decoding fails.
     */
    @inlinable
    final public func getResponse<RouterType: APIRouter>(from router: RouterType) async throws -> RouterType.Response where RouterType.AuthorizationType == AuthorizationType, RouterType.Response: Decodable {
        let data = try await getData(for: router)
        return try await getDecoded(from: data, decoder: router.jsonDecoder)
    }
    
    /**
     Fetches data from the network using a given `APIRouter`.
     
     This method fetches the data from the network using the given `APIRouter` and reports the progress of the request to the `eventDelegate` if it is set.
     
     - Parameter router: The `APIRouter` object representing the network request.
     - Throws: An error if the network request fails.
     - Note: `RouterType.AuthorizationType` must match the `AuthorizationType` of the `APIService` instance.
     */
    @inlinable
    final public func getResponse<RouterType: APIRouter>(from router: RouterType) async throws -> Void where RouterType.AuthorizationType == AuthorizationType, RouterType.Response == Void {
        try await getData(for: router)
    }
    
    /**
     Fetches data from the network for the specified `APIRouter`.
     
     This method fetches the data from the network using the `URLRequest` created by the `getSignedURLRequest(from:)` method of the given `APIRouter`. The method also supports retry functionality, improving the reliability of data retrieval by retrying the request once if it fails due to an invalid response code or a timeout error. If the request fails with an unauthorized error, it will attempt to fetch the data again using the `getSignedURLRequestOnUnAuthorizedError(from:)` method, and notify the event delegate if the second attempt also fails.
     
     - Parameter router: The `APIRouter` object representing the network request.
     - Returns: The data fetched from the network.
     - Throws: An error if the network request fails.
     - Note: `RouterType.AuthorizationType` must match the `AuthorizationType` of the `APIService` instance.
     */
    @discardableResult
    open func getData<RouterType: APIRouter>(for router: RouterType) async throws -> Data where RouterType.AuthorizationType == AuthorizationType {
        do {
            return try await getDataFromNetwork(for: try await getURLRequest(from: router))
        }  catch let error as ResponseValidationError where error == .invalidResponseCode {
            return try await getDataFromNetwork(for: try await getURLRequest(from: router))
        } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorTimedOut {
            return try await getDataFromNetwork(for: try await getURLRequest(from: router))
        } catch ResponseValidationError.unauthorized {
            let request = try await getURLRequestOnUnAuthorizedError(from: router)
            do {
                return try await getDataFromNetwork(for: request)
            } catch {
                await eventDelegate?.requestFailedWithUnAuthorizedError(request: request)
                throw error
            }
        }
    }
    
    /**
     Returns a URL request created by a given `APIRouter`.
     
     This method creates a `URLRequest` using the `getURLRequest(from:)` method of the `URLRequestProvider`.
     
     - Parameter router: The `APIRouter` object representing the network request.
     - Returns: A `URLRequest` object.
     - Throws: An error if the `URLRequest` could not be created from the `APIRouter`.
     - Note: `RouterType.AuthorizationType` must match the `AuthorizationType` of the `APIService` instance.
     */
    @inlinable
    final func getURLRequest<RouterType: APIRouter>(from router: RouterType) async throws -> URLRequest where RouterType.AuthorizationType == AuthorizationType {
        try await urlRequestProvider.getURLRequest(from: router)
    }
    
    /**
     Returns a URL request created by a given `APIRouter` when an unauthorized error occurs.
     
     This method creates a `URLRequest` using the `getURLRequestOnUnAuthorizedError(from:)` method of the `URLRequestProvider`.
     
     - Parameter router: The `APIRouter` object representing the network request.
     - Returns: A `URLRequest` object.
     - Throws: An error if the `URLRequest` could not be created from the `APIRouter`.
     - Note: `RouterType.AuthorizationType` must match the `AuthorizationType` of the `APIService` instance.
     */
    @inlinable
    final func getURLRequestOnUnAuthorizedError<RouterType: APIRouter>(from router: RouterType) async throws -> URLRequest where RouterType.AuthorizationType == AuthorizationType {
        try await urlRequestProvider.getURLRequestOnUnAuthorizedError(from: router)
    }
    
    /**
     Decodes the data using the specified `JSONDecoder`.
     
     This method decodes the given data using the specified `JSONDecoder`. It also reports the progress of the decoding to the `eventDelegate` if it is set.
     
     - Parameters:
     - data: The data to be decoded.
     - decoder: The `JSONDecoder` to use for decoding the data.
     - Returns: A decoded object of the specified type.
     - Throws: An error if the decoding fails.
     */
    final public func getDecoded<T: Decodable>(from data: Data, decoder: JSONDecoder) async throws -> T {
        let decoded: T = try decoder.decode(T.self, from: data)
        
        eventDelegate?.responseDecoded(decoded)
        
        return decoded
    }
    
    /**
     Fetches data from the network using a given `URLRequest`.
     
     This method fetches the data from the network using the given `URLRequest`. It also reports the progress of the request to the `eventDelegate` if it is set.
     
     - Parameter request: The `URLRequest` to use for fetching the data.
     - Returns: The data fetched from the network.
     - Throws: An error if the network request fails.
     */
    final public func getDataFromNetwork(for request: URLRequest) async throws -> Data {
        eventDelegate?.requestFired(request: request)
        
        let (data, response) = try await networkingService.data(for: request)
        eventDelegate?.responseReceived(from: request, data: data, response: response)
        
        try checkResponse(from: data, with: response)
        
        return data
    }
    
    /**
     Checks the HTTP response for errors, throwing a `ResponseValidationError` if the response is invalid.
     
     - Parameter data: The data returned from the request.
     - Parameter response: The HTTP response received from the server.
     
     - Throws: A `ResponseValidationError` if the response is invalid.
     */
    @inlinable
    open func checkResponse(from data: Data, with response: URLResponse) throws {
        if let error = ResponseValidationError(response: response) {
            throw error
        }
    }
}
