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
