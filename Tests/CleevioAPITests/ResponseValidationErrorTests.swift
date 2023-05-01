//
//  ResponseValidationErrorTests.swift
//  
//
//  Created by Lukáš Valenta on 01.05.2023.
//

import XCTest
import CleevioAPI

final class ResponseValidationErrorTests: XCTestCase {
    
    func testInitWithValidResponse() {
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
        let error = ResponseValidationError(response: response)
        XCTAssertEqual(error, nil)
    }
    
    func testInitWithStatusCode300() {
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 300, httpVersion: "HTTP/1.1", headerFields: nil)!
        let error = ResponseValidationError(response: response)
        XCTAssertEqual(error, nil)
    }
    
    func testInitWithClientError() {
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 401, httpVersion: "HTTP/1.1", headerFields: nil)!
        let error = ResponseValidationError(response: response)
        XCTAssertEqual(error, .unauthorized)
    }
    
    func testInitWithServerError() {
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 500, httpVersion: "HTTP/1.1", headerFields: nil)!
        let error = ResponseValidationError(response: response)
        XCTAssertEqual(error, .invalidResponseCode)
    }
    
    func testInitWithNonHTTPURLResponse() {
        let response = URLResponse(url: URL(string: "https://example.com")!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let error = ResponseValidationError(response: response)
        XCTAssertEqual(error, .notHTTPURLResponse)
    }

    func testInitWithBadRequest() {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                          statusCode: 400,
                                          httpVersion: nil,
                                          headerFields: nil)!
        let responseValidationError = ResponseValidationError(response: urlResponse)
        XCTAssertEqual(responseValidationError, .badRequest)
    }

    func testInitWithUnauthorized() {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                          statusCode: 401,
                                          httpVersion: nil,
                                          headerFields: nil)!
        let responseValidationError = ResponseValidationError(response: urlResponse)
        XCTAssertEqual(responseValidationError, .unauthorized)
    }

    func testInitWithAccessDenied() {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                          statusCode: 403,
                                          httpVersion: nil,
                                          headerFields: nil)!
        let responseValidationError = ResponseValidationError(response: urlResponse)
        XCTAssertEqual(responseValidationError, .accessDenied)
    }

    func testInitWithNotFound() {
        // Not found
        let urlResponse = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                          statusCode: 404,
                                          httpVersion: nil,
                                          headerFields: nil)!
        let responseValidationError = ResponseValidationError(response: urlResponse)
        XCTAssertEqual(responseValidationError, .notFound)
    }

}

