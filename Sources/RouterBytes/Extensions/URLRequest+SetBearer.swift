//
//  URLRequest+SetBearer.swift
//  
//
//  Created by Lukáš Valenta on 30.04.2023.
//

import Foundation

public extension URLRequest {
    /// Sets a bearer token in the `Authorization` header field of the request.
    ///
    /// - Parameter token: A string containing the bearer token to be set in the Authorization header field.
    ///
    /// - Note: This method mutates the current `URLRequest` instance.
    ///
    /// - Warning: If the `Authorization` header field is already set, calling this method will overwrite its value.
    ///
    /// Example usage:
    /// ```
    /// var request = URLRequest(url: URL(string: "https://example.com/api")!)
    /// request.setBearerToken("abc123")
    /// ```
    @inlinable
    mutating func setBearerToken(_ token: String) {
        setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    
    /// Returns a new URLRequest instance with the specified bearer token set in its Authorization header field.
    ///
    /// Parameter token: A string containing the bearer token to be set in the Authorization header field.
    /// Returns: A new URLRequest instance with the Authorization header field set to "Bearer {token}".
    ///
    /// - Warning: If the `Authorization` header field is already set, calling this method will overwrite its value.
    ///
    /// Example usage:
    /// ```
    /// var request = URLRequest(url: URL(string: "https://example.com/api")!)
    /// request.setBearerToken("abc123")
    /// ```
    @inlinable
    func withBearerToken(_ token: String) -> URLRequest {
        var request = self
        request.setBearerToken(token)
        
        return request
    }
}
