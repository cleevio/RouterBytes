//
//  APIService.swift
//  
//
//  Created by Lukáš Valenta on 30.04.2023.
//

import Foundation


/**
`APIService` is a class responsible for making network requests and decoding responses. It uses an implementation of `NetworkingServiceType` protocol to actually perform the network requests.

To use `APIService`, subclass it and override its methods as needed. The `getData` method is the most commonly used method for fetching data from the network. You pass an implementation of `APIRouter` to `getData` and it returns the decoded `APIRouter.Response`.

`APIService` also has an optional `APIServiceEventDelegate` to which it reports the progress of the requests.
*/
@available(macOS 12.0, *)
open class APIService {
    /// The networking service used to perform network requests.
    public final let networkingService: NetworkingServiceType

    /// An optional delegate that can be used to receive events from the `APIService` object.
    public final var eventDelegate: APIServiceEventDelegate?

    /**
     Initializes an `APIService` object with a specified networking service.
     
     - Parameter networkingService: The networking service to use for network requests.
     */
    @inlinable
    public init(networkingService: NetworkingServiceType) {
        self.networkingService = networkingService
    }

    /**
     Fetches data from the network using a given router.
     
     This method fetches the data from the network using a `URLRequest` created by the `asURLRequest` method of the given `APIRouter`. The data is then decoded using the `jsonDecoder` property of the router.
     
     - Parameter router: The router to use for creating the request.
     - Returns: A decoded response object of type `RouterType.Response`.
     - Throws: An error if the network request or decoding fails.
     */
    open func getData<RouterType: APIRouter>(from router: RouterType) async throws -> RouterType.Response {
        try await getDecoded(from: try await getSignedURLRequest(from: router), decoder: router.jsonDecoder)
    }

    /**
     Returns a signed URL request created by a given router.
     
     This method creates and signs a `URLRequest` using the `asURLRequest` method of the given `APIRouter`.
     
     - Parameter router: The router to use for creating the request.
     - Returns: A signed `URLRequest` object.
     - Throws: An error if the URLRequest could not be created from APIRouter.
     */
    @inlinable
    open func getSignedURLRequest(from router: some APIRouter) async throws -> URLRequest {
        try router.asURLRequest()
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
    open func getDecoded<T: Decodable>(from request: URLRequest, decoder: JSONDecoder) async throws -> T {
        let data = try await getData(from: request)
        
        let decoded: T = try {
            if T.self is EmptyCodable.Type, let empty = EmptyCodable() as? T {
               return empty
            }

            return try decoder.decode(T.self, from: data)
        }()

        eventDelegate?.responseDecoded(decoded)
        
        return decoded
    }

    /**
     Fetches data from the network using a given `URLRequest`.
     
     This method fetches the data from the network using the given `URLRequest`. It also reports the progress of the request to the `eventDelegate` if it is set.
     
     - Parameter request: The `URLRequest` to use for fetching the data.
     - Returns: The data fetched from the network.
     */
    open func getData(from request: URLRequest) async throws -> Data {
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
