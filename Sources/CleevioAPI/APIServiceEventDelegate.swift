//
//  APIServiceDelegate.swift
//  
//
//  Created by Lukáš Valenta on 30.04.2023.
//

import Foundation

/// A protocol for handling events in an API service.
/// An object implementing this protocol can receive callbacks from an `APIService` instance when certain events occur during a network request.
///
/// Example usage:
/// ```
///struct MyAPIServiceDelegate: APIServiceDelegate {
///    func requestFired(request: URLRequest) {
///        log.info(request.cURL(pretty: true)
///    }
///
///    func responseReceived(data: Data, response: URLResponse) {
///        log.debug("Request: \(request)\nResponse: \(data.asJSONString(pretty: true) ?? "could not parse")")
///    }
///
///    func responseDecoded<T>(_ value: T) {
///        log.debug(decoded)
///    }
///}
/// ```
public protocol APIServiceEventDelegate: Sendable {
    /**
     Notifies the delegate that a network request has been fired.
     
     - Parameter request: The URLRequest instance that was fired.
     */
    func requestFired(request: URLRequest)

    /**
     Notifies the delegate that a network response has been received.
     
     - Parameters:
        - data: The data returned in the response.
        - response: The URLResponse object for the response.
     */
    func responseReceived(data: Data, response: URLResponse)

    /**
     Notifies the delegate that a response has been decoded.
     
     - Parameter value: The decoded value of type `T`.
     */
    func responseDecoded<T>(_ value: T)

}




