//
//  ResponseValidationError.swift
//  
//
//  Created by Lukáš Valenta on 30.04.2023.
//

import Foundation

/// An error that occurs when a response is not valid.
public enum ResponseValidationError: Error, Equatable {

    /// Initializes a `ResponseValidationError` instance from the provided `URLResponse`.
    ///
    /// If the provided URLResponse is not an `HTTPURLResponse`, the `ResponseValidationError` instance is set to `.notHTTPURLResponse`.
    ///
    /// If the status code of the `HTTPURLResponse` is outside the valid range of `ResponseStatusCode.valid`, the `ResponseValidationError` instance is set to `.invalidResponseCode`.
    ///
    /// If the status code of the `HTTPURLResponse` falls within the range of `ResponseStatusCode.clientError` or `ResponseStatusCode.serverError`, the `ResponseValidationError` instance is set to one of the corresponding cases:
    ///
    /// - `.badRequest` for status code `400`
    /// - `.unauthorized` for status code `401`
    /// - `.accessDenied` for status code `403`
    /// - `.notFound` for status code `404`
    /// - `.internalError` for all other status codes in the range
    ///
    /// Otherwise, returns `nil`.
    ///
    /// - Parameter response: The `URLResponse` to validate.
    public init?(response: URLResponse) {
        guard let httpResponse = response as? HTTPURLResponse else {
            self = .notHTTPURLResponse
            return
        }

        guard ResponseStatusCode.valid ~= httpResponse.statusCode else {
            self = .invalidResponseCode
            return
        }

        if (ResponseStatusCode.clientError ~= httpResponse.statusCode) ||
            (ResponseStatusCode.serverError ~= httpResponse.statusCode) {
            switch httpResponse.statusCode {
            case 400:
                self = .badRequest
            case 401:
                self = .unauthorized
            case 403:
                self = .accessDenied
            case 404:
                self = .notFound
            default:
                self = .internalError
            }
        } else {
            return nil
        }
    }

    /// An error that occurs when the response is invalid.
    case invalidResponse(message: String?)
    
    /// An error that occurs when the response is not an HTTP URL response.
    case notHTTPURLResponse
    
    /// An error that occurs when the request is not valid.
    case invalidRequest
    
    /// An error that occurs when the request is bad.
    case badRequest
    
    /// An error that occurs when the user is not authorized.
    case unauthorized
    
    /// An error that occurs when the user is denied access.
    case accessDenied
    
    /// An error that occurs when the requested resource is not found.
    case notFound
    
    /// An error that occurs when there is an internal error.
    case internalError
    
    /// An error that occurs when the response code is invalid.
    case invalidResponseCode
}

extension ResponseValidationError: LocalizedError {
    /// A localized description of the error.
    public var errorDescription: String? {
        switch self {
        case let .invalidResponse(message):
            return message
        case .notHTTPURLResponse:
            return NSLocalizedString("Not HTTP URL Response", comment: "")
        case .invalidRequest:
            return NSLocalizedString("Invalid request", comment: "")
        case .badRequest:
            return NSLocalizedString("Bad request", comment: "")
        case .unauthorized:
            return NSLocalizedString("Unauthorized", comment: "")
        case .accessDenied:
            return NSLocalizedString("Access denied", comment: "")
        case .notFound:
            return NSLocalizedString("Not found", comment: "")
        case .internalError:
            return NSLocalizedString("Internal error", comment: "")
        case .invalidResponseCode:
            return NSLocalizedString("Invalid response code", comment: "")
        }
    }
}
