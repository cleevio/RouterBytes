//
//  TokenAPIServiceTests.swift
//
//
//  Created by Lukáš Valenta on 05.05.2023.
//

import Foundation
import XCTest
import CleevioAuthentication
import CleevioAPI

fileprivate var dateProvider = DateProviderMock(date: Date())

@available(iOS 15.0, *)
class TokenAPIServiceTests: XCTestCase {
    var networkingService: NetworkingServiceMock!
    var apiService: TokenAPIService<BaseAPIToken, AuthorizationType, TokenManager<BaseAPIToken, RefreshTokenRouter>>!
    var tokenManager: TokenManager<BaseAPIToken, RefreshTokenRouter>!
    var delegate: MockAPIServiceEventDelegate!
    var onNetworkCall: ((URLRequest) -> (Data, URLResponse))!
    var tokenRepository: APITokenRepositoryMock<BaseAPIToken>!
    
    var _apiServiceInitializer: TokenAPIService<BaseAPIToken, AuthorizationType, TokenManager<BaseAPIToken, RefreshTokenRouter>>! {
        TokenAPIService(tokenManager: tokenManager, networkingService: networkingService)
    }

    override func setUp() {
        super.setUp()
        
        dateProvider = .init(date: Date())
        self.networkingService = NetworkingServiceMock(onDataCall: { request, _ in
            self.onNetworkCall(request)
        })

        tokenRepository = APITokenRepositoryMock(apiToken: nil)

        tokenManager = TokenManager(
            apiService: APIService(networkingService: networkingService),
            dateProvider: dateProvider,
            apiTokenRepository: tokenRepository
        )

        apiService = _apiServiceInitializer
        delegate = MockAPIServiceEventDelegate()
        apiService.eventDelegate = delegate
    }
    
    override func tearDown() {
        networkingService = nil
        apiService = nil
        delegate = nil
        super.tearDown()
    }

    func testLogoutOnFailureAndRefreshFailure() async throws {
        let router: BaseAPIRouter<String, String> = Self.mockRouter(authType: .bearer(.accessToken))
        tokenRepository.apiToken.store(.init(accessToken: "best-access-Token", refreshToken: "best-refresh-Token", expiration: Date.distantFuture))
        let expectedInitialRequest = self.setBearerTokenHelper(urlRequest: try router.asURLRequest(), token: "best-access-Token")
        let receivedInitialResponse = HTTPURLResponse(url: expectedInitialRequest.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!

        let firstRequest = XCTestExpectation(description: "First request should fire")
        let secondRequest = XCTestExpectation(description: "Second request should fire")

        
        self.onNetworkCall =  { request in
            XCTAssertEqual(expectedInitialRequest, request)
            firstRequest.fulfill()

            self.onNetworkCall = { request in
                secondRequest.fulfill()
                return (Data(), receivedInitialResponse)
            }
            
            return (Data(), receivedInitialResponse)
        }
        
        do {
            // Perform the data request, which should trigger token refreshing and retry the request
            _ = try await apiService.getData(from: router)
            XCTFail()
        } catch {
            // Wait for expectations to be fulfilled

            wait(for: [firstRequest, secondRequest], timeout: 1)
            
            // Ensure that the request was retried and succeeded
            XCTAssertEqual(delegate.receivedResponse, receivedInitialResponse)
            XCTAssertEqual(delegate.firedRequest, expectedInitialRequest)
            
            // Ensure user was logged out
            
            XCTAssertEqual(tokenRepository.apiToken.value, nil)

            do {
                _ = try await tokenManager.getAccessToken(forceRefresh: false)
                XCTFail()
            } catch {
                
            }
            
            do {
                _ = try await tokenManager.getRefreshToken()
                XCTFail()
            } catch { }
        }
    }

    func testRetryOnInternalErrorFailure() async throws {
        let router: BaseAPIRouter<String, String> = Self.mockRouter(authType: .bearer(.accessToken))
        tokenRepository.apiToken.store(.init(accessToken: "best-access-Token", refreshToken: "best-refresh-Token", expiration: Date.distantFuture))
        let expectedRequest = self.setBearerTokenHelper(urlRequest: try router.asURLRequest(), token: "best-access-Token")
        let receivedResponse = HTTPURLResponse(url: expectedRequest.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!

        let firstRequest = XCTestExpectation(description: "First request should fire")
        let secondRequest = XCTestExpectation(description: "Second request should fire")

        
        self.onNetworkCall =  { request in
            XCTAssertEqual(expectedRequest, request)
            firstRequest.fulfill()

            self.onNetworkCall = { request in
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

            do {
                let accessToken = try await tokenManager.getAccessToken(forceRefresh: false)
                let refreshToken = try await tokenManager.getRefreshToken()

                XCTAssertEqual(accessToken, "best-access-Token")
                XCTAssertEqual(refreshToken, "best-refresh-Token")
            } catch {
                print(error)
                XCTFail()
            }
        }
    }

    func testRetryOnInternalErrorSuccess() async throws {
        let router: BaseAPIRouter<String, String> = Self.mockRouter(authType: .bearer(.accessToken))
        tokenRepository.apiToken.store(.init(accessToken: "best-access-Token", refreshToken: "best-refresh-Token", expiration: Date.distantFuture))
        let expectedRequest = self.setBearerTokenHelper(urlRequest: try router.asURLRequest(), token: "best-access-Token")
        let receivedResponse = HTTPURLResponse(url: expectedRequest.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
        let receivedSuccessResponse = HTTPURLResponse(url: expectedRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        let expectedData = "Hello, World!"
        let responseData = try JSONEncoder().encode(expectedData)

        let firstRequest = XCTestExpectation(description: "First request should fire")
        let secondRequest = XCTestExpectation(description: "Second request should fire")

        
        self.onNetworkCall =  { request in
            XCTAssertEqual(expectedRequest, request)
            firstRequest.fulfill()

            self.onNetworkCall = { request in
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

        do {
            let accessToken = try await tokenManager.getAccessToken(forceRefresh: false)
            let refreshToken = try await tokenManager.getRefreshToken()

            XCTAssertEqual(accessToken, "best-access-Token")
            XCTAssertEqual(refreshToken, "best-refresh-Token")
        } catch {
            print(error)
            XCTFail()
        }
    }
    
    func getDataTestHelper(router: BaseAPIRouter<String, String>,
                           expectedRequest: URLRequest,
                           file: StaticString = #filePath,
                           line: UInt = #line) async throws {
        let expectedResponse = "Hello, World!"
        let responseData = try JSONEncoder().encode(expectedResponse)
        let receivedResponse = HTTPURLResponse(url: expectedRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!

        onNetworkCall = { request in
            XCTAssertEqual(request, expectedRequest, file: file, line: line)
            return (responseData, receivedResponse)
        }
        
        let response = try await apiService.getData(from: router)
        
        XCTAssertEqual(response, expectedResponse, file: file, line: line)
        XCTAssertEqual(delegate.receivedData, responseData, file: file, line: line)
        XCTAssertEqual(delegate.receivedResponse, receivedResponse, file: file, line: line)
        XCTAssertEqual(delegate.firedRequest, expectedRequest, file: file, line: line)
        XCTAssertNotNil(delegate.decodedValue as? String, file: file, line: line)
    }

    func setBearerTokenHelper(urlRequest: URLRequest, token: String) -> URLRequest {
        // The request stays the same as TokenAPIService needs to be specialized
        return urlRequest
    }

    static func mockRouter<Response: Decodable>(authType: AuthorizationType) -> BaseAPIRouter<String, Response> {
        BaseAPIRouter(hostname: URL(string: "https://cleevio.com")!, path: "/blog", authType: authType)
    }
}
