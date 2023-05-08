//
//  APIService.swift
//  
//
//  Created by Lukáš Valenta on 30.04.2023.
//

import Foundation

/**
 `APIService` is a class responsible for making network requests and decoding responses. It uses an implementation of the `NetworkingServiceType` protocol to perform the network requests.

 To use `APIService`, subclass it and override its methods as needed. The most commonly used method is `getData`, which fetches data from the network. You pass an implementation of the `APIRouter` to `getData`, and it returns the decoded `APIRouter.Response`.

 `APIService` supports retry functionality in the `getData` method. If the network request fails due to an invalid response code or a timeout error, it will retry the request once. This behavior helps improve the reliability of data retrieval.

 The class also provides an optional `APIServiceEventDelegate` that can be used to receive events from the `APIService` object, such as progress updates and response decoding notifications.

 The generic `AuthorizationType` represents the type of authorization used by the network requests. It is specified when creating an instance of `APIService`.

 - Example usage:
 ```
 let networkingService = YourNetworkingService()
 let apiService = APIService<YourAuthorizationType>(networkingService: networkingService)

 let router = YourAPIRouter()
 do {
     let responseData: YourResponseDataType = try await apiService.getData(from: router)
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

    /**
     Initializes an `APIService` object with a specified networking service.
     
     - Parameter networkingService: The networking service to use for network requests.
     */
    @inlinable
    public init(networkingService: NetworkingServiceType, eventDelegate: APIServiceEventDelegate? = nil) {
        self.networkingService = networkingService
        self.eventDelegate = eventDelegate
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
    final public func getData<RouterType: APIRouter>(from router: RouterType) async throws -> RouterType.Response where RouterType.AuthorizationType == AuthorizationType, RouterType.Response: Decodable {
        let data = try await getData(for: router, request: try await getSignedURLRequest(from: router))
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
    final public func getData<RouterType: APIRouter>(from router: RouterType) async throws -> Void where RouterType.AuthorizationType == AuthorizationType, RouterType.Response == Void {
        try await getData(for: router, request: try await getSignedURLRequest(from: router))
    }

    /**
     Fetches data from the network for the specified `APIRouter`.

     This method fetches the data from the network using the `URLRequest` created by the `asURLRequest()` method of the given `APIRouter`. The method also supports retry functionality, improving the reliability of data retrieval by retrying the request once if it fails due to an invalid response code or a timeout error.

     - Parameter router: The `APIRouter` object representing the network request.
     - Parameter request: A closure that asynchronously returns the `URLRequest` object to be used for the network request.
     - Returns: The data fetched from the network.
     - Throws: An error if the network request fails.
     - Note: `RouterType.AuthorizationType` must match the `AuthorizationType` of the `APIService` instance.
     */
    @discardableResult
    open func getData<RouterType: APIRouter>(for router: RouterType, request: @autoclosure () async throws -> URLRequest) async throws -> Data where RouterType.AuthorizationType == AuthorizationType {
        do {
            return try await getDataFromNetwork(for: try await request())
        }  catch let error as ResponseValidationError where error == .invalidResponseCode {
            return try await getDataFromNetwork(for: try await request())
        } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorTimedOut {
            return try await getDataFromNetwork(for: try await request())
        }
    }

    /**
     Returns a signed URL request created by a given `APIRouter`.

     This method creates and signs a `URLRequest` using the `asURLRequest()` method of the given `APIRouter`.

     - Parameter router: The `APIRouter` object representing the network request.
     - Returns: A signed `URLRequest` object.
     - Throws: An error if the `URLRequest` could not be created from the `APIRouter`.
     - Note: `RouterType.AuthorizationType` must match the `AuthorizationType` of the `APIService` instance.
     */
    @inlinable
    open func getSignedURLRequest<RouterType: APIRouter>(from router: RouterType) async throws -> URLRequest where RouterType.AuthorizationType == AuthorizationType {
        try router.asURLRequest()
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
        eventDelegate?.responseReceived(data: data, response: response)

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
