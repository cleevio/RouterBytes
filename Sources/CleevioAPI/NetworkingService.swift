//
//  NetworkingService.swift
//  
//
//  Created by Lukáš Valenta on 30.04.2023.
//

import Foundation

@available(macOS 12.0, *)
public protocol NetworkingServiceType {
    func finishTasksAndInvalidate()
    func invalidateAndCancel()
    func reset() async

    func data(for request: URLRequest) async throws -> (Data, URLResponse)
    @available(iOS 15.0, *)
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)
    @available(iOS 15.0, *)
    func bytes(for request: URLRequest, delegate: (URLSessionTaskDelegate)?) async throws -> (URLSession.AsyncBytes, URLResponse)
}

@available(macOS 12.0, *)
public extension NetworkingServiceType {
    @available(iOS 15.0, *)
    @inlinable
    func bytes(for request: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse) {
        try await bytes(for: request, delegate: nil)
    }
}

@available(macOS 12.0, *)
public struct NetworkingService: NetworkingServiceType {
    public let urlSession: URLSession

    @inlinable
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    @inlinable
    public func finishTasksAndInvalidate() {
        urlSession.finishTasksAndInvalidate()
    }
    
    @inlinable
    public func invalidateAndCancel() {
        urlSession.invalidateAndCancel()
    }
    
    @inlinable
    public func reset() async {
        await urlSession.reset()
    }

    @inlinable
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await urlSession.data(for: request)
    }

    @inlinable
    @available(iOS 15.0, *)
    public func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        try await urlSession.data(for: request, delegate: delegate)
    }
    
    @available(iOS 15.0, *)
    public func bytes(for request: URLRequest, delegate: (URLSessionTaskDelegate)? = nil) async throws -> (URLSession.AsyncBytes, URLResponse) {
        try await urlSession.bytes(for: request, delegate: delegate)
    }
}


@available(macOS 12.0, *)
@available(iOS 15.0, *)
public final class NetworkingServiceMock: NetworkingServiceType {
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
