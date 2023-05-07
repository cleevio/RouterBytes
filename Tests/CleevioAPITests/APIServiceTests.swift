//
//  APIServiceTests.swift
//  
//
//  Created by Lukáš Valenta on 30.04.2023.
//

import XCTest
import CleevioAPI

@available(iOS 15.0, *)
final class APIServiceTests: XCTestCase {
    var networkingService: NetworkingServiceMock!
    var apiService: APIService<AuthorizationType>!
    var delegate: MockAPIServiceEventDelegate!
    
    override func setUp() {
        super.setUp()
        
        networkingService = NetworkingServiceMock()
        apiService = APIService(networkingService: networkingService)
        delegate = MockAPIServiceEventDelegate()
        apiService.eventDelegate = delegate
    }
    
    override func tearDown() {
        networkingService = nil
        apiService = nil
        delegate = nil
        super.tearDown()
    }
    
    func testGetData() async throws {
        let router: BaseAPIRouter<String, String> = Self.mockRouter()
        let request = try router.asURLRequest()
        let expectedResponse = "Hello, World!"
        let responseData = try JSONEncoder().encode(expectedResponse)
        let receivedResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        networkingService.onDataCall = { request, _ in
            (responseData, receivedResponse)
        }
        
        let response = try await apiService.getData(from: router)
        
        XCTAssertEqual(response, expectedResponse)
        XCTAssertEqual(delegate.receivedData, responseData)
        XCTAssertEqual(delegate.receivedResponse, receivedResponse)
        XCTAssertEqual(delegate.firedRequest, request)
        XCTAssertNotNil(delegate.decodedValue as? String)
    }

    func testRetryOnInternalErrorFailure() async throws {
        let router: BaseAPIRouter<String, String> = Self.mockRouter()
        let expectedRequest = try router.asURLRequest()
        let receivedResponse = HTTPURLResponse(url: expectedRequest.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!

        let firstRequest = XCTestExpectation(description: "First request should fire")
        let secondRequest = XCTestExpectation(description: "Second request should fire")

        
        networkingService.onDataCall = { request, _ in
            XCTAssertEqual(expectedRequest, request)
            firstRequest.fulfill()

            self.networkingService.onDataCall = { request, _ in
                XCTAssertEqual(expectedRequest, request)
                secondRequest.fulfill()
                return (Data(), receivedResponse)
            }
            
            return (Data(), receivedResponse)
        }
    
        do {
            // Perform the data request, which should trigger token refreshing and retry the request
            let response = try await apiService.getData(from: router)
            XCTFail()
        } catch {
            // Ensure that the request was retried and succeeded
            XCTAssertEqual(delegate.receivedResponse, receivedResponse)
            XCTAssertEqual(delegate.firedRequest, expectedRequest)

            // Wait for expectations to be fulfilled
            wait(for: [firstRequest, secondRequest], timeout: 1)
        }
    }

    func testRetryOnInternalErrorSuccess() async throws {
        let router: BaseAPIRouter<String, String> = Self.mockRouter()
        let expectedRequest = try router.asURLRequest()
        let receivedResponse = HTTPURLResponse(url: expectedRequest.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
        let receivedSuccessResponse = HTTPURLResponse(url: expectedRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        let expectedData = "Hello, World!"
        let responseData = try JSONEncoder().encode(expectedData)

        let firstRequest = XCTestExpectation(description: "First request should fire")
        let secondRequest = XCTestExpectation(description: "Second request should fire")

        
        networkingService.onDataCall = { request, _ in
            XCTAssertEqual(expectedRequest, request)
            firstRequest.fulfill()

            self.networkingService.onDataCall = { request, _ in
                XCTAssertEqual(expectedRequest, request)
                secondRequest.fulfill()
                return (responseData, receivedSuccessResponse)
            }
            
            return (Data(), receivedResponse)
        }
    
        // Perform the data request, which should trigger token refreshing and retry the request
        let response = try await apiService.getData(from: router)

        // Ensure that the request was retried and succeeded
        XCTAssertEqual(delegate.receivedResponse, receivedSuccessResponse)
        XCTAssertEqual(response, expectedData)
        XCTAssertEqual(delegate.decodedValue as? String, expectedData)
        XCTAssertEqual(delegate.firedRequest, expectedRequest)
        XCTAssertNotNil(delegate.decodedValue as? String)

        // Wait for expectations to be fulfilled
        wait(for: [firstRequest, secondRequest], timeout: 1)
    }

    func testRetryOnTimeout() async throws {
        let router: BaseAPIRouter<String, String> = Self.mockRouter()
        let expectedRequest = try router.asURLRequest()
        let receivedResponse = HTTPURLResponse(url: expectedRequest.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
        let receivedSuccessResponse = HTTPURLResponse(url: expectedRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        let expectedData = "Hello, World!"
        let responseData = try JSONEncoder().encode(expectedData)

        let firstRequest = XCTestExpectation(description: "First request should fire")
        let secondRequest = XCTestExpectation(description: "Second request should fire")

        
        networkingService.onDataCall = { request, _ in
            XCTAssertEqual(expectedRequest, request)
            firstRequest.fulfill()

            self.networkingService.onDataCall = { request, _ in
                XCTAssertEqual(expectedRequest, request)
                secondRequest.fulfill()
                return (responseData, receivedSuccessResponse)
            }
            
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        }
    
        // Perform the data request, which should trigger token refreshing and retry the request
        let response = try await apiService.getData(from: router)

        // Ensure that the request was retried and succeeded
        XCTAssertEqual(delegate.receivedResponse, receivedSuccessResponse)
        XCTAssertEqual(response, expectedData)
        XCTAssertEqual(delegate.decodedValue as? String, expectedData)
        XCTAssertEqual(delegate.firedRequest, expectedRequest)
        XCTAssertNotNil(delegate.decodedValue as? String)

        // Wait for expectations to be fulfilled
        wait(for: [firstRequest, secondRequest], timeout: 1)
    }

    static private func mockRouter<Response: Decodable>() -> BaseAPIRouter<String, Response> {
        BaseAPIRouter(hostname: URL(string: "https://cleevio.com")!, path: "/blog", authType: .none)
    }
}


final class MockAPIServiceEventDelegate: APIServiceEventDelegate {
    var firedRequest: URLRequest?
    var receivedData: Data?
    var receivedResponse: URLResponse?
    var decodedValue: Any?
    
    func requestFired(request: URLRequest) {
        firedRequest = request
    }
    
    func responseReceived(data: Data, response: URLResponse) {
        receivedData = data
        receivedResponse = response
    }
    
    func responseDecoded<T>(_ value: T) {
        decodedValue = value
    }
}
