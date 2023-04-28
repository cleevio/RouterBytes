//
//  APIRouterError.swift
//  
//
//  Created by Lukáš Valenta on 28.04.2023.
//

import Foundation

public enum APIRouterError: LocalizedError {
    /// The URLComponents object used to build the request URL was invalid.
    case invalidURL(components: URLComponents)

    /// The hostname specified in the `APIRouter` was invalid or could not be resolved.
    case invalidHostname

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let components):
            return NSLocalizedString("Invalid URL Components",
                                     comment: "An error message indicating that the provided URL components were invalid.")
                + ": \(components)"
        case .invalidHostname:
            return NSLocalizedString("Invalid Hostname",
                                     comment: "An error message indicating that the provided hostname was invalid.")
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("One or more URL components were invalid",
                                     comment: "A more detailed explanation of the Invalid URL Components error.")
        case .invalidHostname:
            return NSLocalizedString("The hostname specified in the APIRouter was invalid or could not be resolved.",
                                     comment: "A more detailed explanation of the Invalid Hostname error.")
        }
    }
}
