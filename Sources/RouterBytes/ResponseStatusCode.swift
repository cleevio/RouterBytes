//
//  ResponseStatusCode.swift
//  
//
//  Created by Lukáš Valenta on 30.04.2023.
//

import Foundation

/// An enumeration of common HTTP response status codes and their corresponding integer values.
public enum ResponseStatusCode: Sendable {
    
    /// The HTTP status code for a successful request.
    ///
    /// A response with this status code indicates that the request has been successfully processed and that the response body contains the requested data.
    public static let ok: Int = 200
    
    /// The HTTP status code for a successfully created resource.
    ///
    /// This status code indicates that a new resource has been successfully created on the server.
    public static let created: Int = 201
    
    /// The HTTP status code for an accepted request.
    ///
    /// This status code indicates that the request has been accepted for processing, but that the processing may not be complete.
    public static let accepted: Int = 202
    
    /// The HTTP status code for unauthorized access.
    ///
    /// This status code indicates that the client must authenticate itself to get the requested response.
    public static let unauthorized: Int = 401
    
    /// The HTTP status code for forbidden access.
    ///
    /// This status code indicates that the client does not have access rights to the content, i.e., they are authenticated but do not have necessary permissions.
    public static let accessDenied: Int = 403
    
    /// The HTTP status code for resource not found.
    ///
    /// This status code indicates that the requested resource could not be found on the server.
    public static let notFound: Int = 404
    
    /// A closed range of successful status codes.
    ///
    /// Responses with status codes within this range indicate that the request has been successfully processed and that the response body contains the requested data.
    public static let success: ClosedRange<Int> = 200...299
    
    /// A closed range of client error status codes.
    ///
    /// Responses with status codes within this range indicate that there was an error in the client request.
    public static let clientError: ClosedRange<Int> = 400...499
    
    /// A closed range of server error status codes.
    ///
    /// Responses with status codes within this range indicate that there was an error on the server while processing the request.
    public static let serverError: ClosedRange<Int> = 500...599
    
    /// A closed range of valid status codes.
    ///
    /// Responses with status codes within this range indicate that the request was valid, but the response may contain a warning or additional information.
    public static let valid: ClosedRange<Int> = 200...499
}
