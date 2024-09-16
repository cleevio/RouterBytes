//
//  NetworkingService.swift
//  
//
//  Created by Lukáš Valenta on 30.04.2023.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@available(macOS 12.0, *)
public protocol NetworkingServiceType: Sendable {
    /// Invalidates the session, allowing any outstanding tasks to finish.
    ///
    /// This method returns immediately without waiting for tasks to finish. Once a session is invalidated, new tasks cannot be created in the session, but existing tasks continue until completion. After the last task finishes and the session makes the last delegate call related to those tasks, the session calls the `urlSession(_:didBecomeInvalidWithError:)` method on its delegate, then breaks references to the delegate and callback objects. After invalidation, session objects cannot be reused.
    /// To cancel all outstanding tasks, call `invalidateAndCancel()` instead.
    ///
    /// - Important: Calling this method on the session returned by the shared method has no effect.
    func finishTasksAndInvalidate()
    
    /// Cancels all outstanding tasks and then invalidates the session.
    ///
    /// Once invalidated, references to the delegate and callback objects are broken. After invalidation, session objects cannot be reused.
    /// To allow outstanding tasks to run until completion, call finishTasksAndInvalidate() instead.
    /// - Important: Calling this method on the session returned by the shared method has no effect.
    func invalidateAndCancel()
    
    /// Empties all cookies, caches and credential stores, removes disk files, flushes in-progress downloads to disk, and ensures that future requests occur on a new socket.
    func reset() async

    /// Downloads the contents of a URL based on the specified URL request and delivers the data asynchronously.
    ///
    /// Use this method to wait until the session finishes transferring data and receive it in a single Data instance. To process the bytes as the session receives them, use `bytes(for:)`.
    ///
    /// - Parameter request: A URL request object that provides request-specific information such as the URL, cache policy, request type, and body data or body stream.
    ///
    /// - Returns: An asynchronously-delivered tuple that contains the URL contents as a Data instance, and a URLResponse.
    func data(for request: URLRequest) async throws -> (Data, URLResponse)

    /// Downloads the contents of a URL based on the specified URL request and delivers the data asynchronously.
    ///
    /// Use this method to wait until the session finishes transferring data and receive it in a single Data instance. To process the bytes as the session receives them, use `bytes(for:delegate:)`.
    ///
    /// - Parameter request: A URL request object that provides request-specific information such as the URL, cache policy, request type, and body data or body stream.
    /// - Parameter delegate: A delegate that receives life cycle and authentication challenge callbacks as the transfer progresses.
    ///
    /// - Returns: An asynchronously-delivered tuple that contains the URL contents as a Data instance, and a URLResponse.
    @available(iOS 15.0, *)
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)

    /// Retrieves the contents of a URL based on the specified URL request and delivers an asynchronous sequence of bytes.
    ///
    /// Use this method when you want to process the bytes while the transfer is underway. You can use a for-await-in loop to handle each byte. For textual data, use the URLSession.AsyncBytes properties characters, unicodeScalars, or lines to receive the content as asynchronous sequences of those types.
    /// To wait until the session finishes transferring data and receive it in a single Data instance, use `data(for:delegate:)`.
    @available(iOS 15.0, *)
    func bytes(for request: URLRequest, delegate: (URLSessionTaskDelegate)?) async throws -> (URLSession.AsyncBytes, URLResponse)
}

@available(macOS 12.0, *)
public extension NetworkingServiceType {
    /// Retrieves the contents of a URL based on the specified URL request and delivers an asynchronous sequence of bytes.
    ///
    /// Use this method when you want to process the bytes while the transfer is underway. You can use a for-await-in loop to handle each byte. For textual data, use the URLSession.AsyncBytes properties characters, unicodeScalars, or lines to receive the content as asynchronous sequences of those types.
    /// To wait until the session finishes transferring data and receive it in a single Data instance, use `data(for:delegate:)`.
    @available(iOS 15.0, *)
    @inlinable
    func bytes(for request: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse) {
        try await bytes(for: request, delegate: nil)
    }
}

extension URLSession: NetworkingServiceType { }

@available(macOS 12.0, *)
@available(iOS 15.0, *)
public final class NetworkingServiceMock: @unchecked Sendable, NetworkingServiceType {
    public var onDataCall: ((URLRequest, URLSessionDelegate?) async throws -> (Data, URLResponse))?
    public var onBytesCall: ((URLRequest, URLSessionTaskDelegate?) async throws -> (URLSession.AsyncBytes, URLResponse))?

    @inlinable
    public init(onDataCall: ((URLRequest, URLSessionDelegate?) async throws -> (Data, URLResponse))? = nil,
                onBytesCall: ((URLRequest, URLSessionTaskDelegate?) async throws -> (URLSession.AsyncBytes, URLResponse))? = nil) {
        self.onDataCall = onDataCall
        self.onBytesCall = onBytesCall
    }

    @inlinable
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: nil)
    }
    
    @inlinable
    public func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        guard let onDataCall else { fatalError("Method was not set") }
        return try await onDataCall(request, delegate)
    }

    @inlinable
    public func bytes(for request: URLRequest, delegate: (URLSessionTaskDelegate)?) async throws -> (URLSession.AsyncBytes, URLResponse) {
        guard let onBytesCall else { fatalError("Method was not set") }
        return try await onBytesCall(request, delegate)
    }
    
    @inlinable
    public func finishTasksAndInvalidate() {
        
    }
  
    @inlinable
    public func invalidateAndCancel() {
        
    }

    @inlinable
    public func reset() async {
        
    }
}
