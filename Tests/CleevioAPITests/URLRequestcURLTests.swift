//
//  URLRequestcURLTests.swift
//  
//
//  Created by Lukáš Valenta on 30.04.2023.
//

import Foundation
import XCTest
import CleevioAPI

class URLRequestcURLTests: XCTestCase {
    let url = URL(string: "https://www.example.com")!
    var request: URLRequest!
    
    override func setUp() {
        super.setUp()
        request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let data = "{\"name\":\"John Doe\", \"age\":30}".data(using: .utf8)
        request.httpBody = data
    }
    
    func testCurlCommand() {
        let expectedCurlCommand = "curl --request POST\\\n--url 'https://www.example.com'\\\n--header 'Content-Type: application/json'\\\n--data '{\n  \"name\" : \"John Doe\",\n  \"age\" : 30\n}'"
        
        let curlCommand = request.cURL(pretty: true)
        XCTAssertEqual(curlCommand, expectedCurlCommand)
    }
    
    func testCurlCommandWithNoBody() {
        request.httpBody = nil
        let expectedCurlCommand = "curl --request POST\\\n--url 'https://www.example.com'\\\n--header 'Content-Type: application/json'"
        
        let curlCommand = request.cURL(pretty: true)
        XCTAssertEqual(curlCommand, expectedCurlCommand)
    }

    func testCurlCommandWithNoBodyNotPretty() {
        request.httpBody = nil
        let expectedCurlCommand = "curl -X POST 'https://www.example.com' -H 'Content-Type: application/json'"
        
        let curlCommand = request.cURL(pretty: false)
        XCTAssertEqual(curlCommand, expectedCurlCommand)
    }

    func testCurlCommandWithDefaultOptions() {
        let expectedCurlCommand = "curl -X POST 'https://www.example.com' -H 'Content-Type: application/json' --data '{\"name\":\"John Doe\", \"age\":30}'"
        
        let curlCommand = request.cURL()
        XCTAssertEqual(curlCommand, expectedCurlCommand)
    }
}
