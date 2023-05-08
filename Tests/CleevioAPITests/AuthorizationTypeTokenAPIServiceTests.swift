//
//  AuthorizationTypeTokenAPIServiceTests.swift
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
final class AuthorizationTypeTokenAPIServiceTests: TokenAPIServiceTests {
    override var _apiServiceInitializer: TokenAPIService<BaseAPIToken, AuthorizationType, TokenManager<BaseAPIToken, RefreshTokenRouter>>! {
        AuthorizationTypeTokenAPIService(tokenManager: tokenManager, networkingService: networkingService, eventDelegate: delegate)
    }
    
    func testGetDataNoAuthorization() async throws {
        let router: BaseAPIRouter<String, String> = Self.mockRouter(authType: .none)
        let expectedRequest = try router.asURLRequest()

        return try await getDataTestHelper(
            router: router,
            expectedRequest: expectedRequest
        )
    }

    func testAccessToken() async throws {
        let router: BaseAPIRouter<String, String> = Self.mockRouter(authType: .bearer(.accessToken))
        let expectedRequest = try router.asURLRequest().withBearerToken("best-access-Token")
        
        tokenRepository.apiToken.store(.init(accessToken: "best-access-Token", refreshToken: "best-refresh-Token", expiration: Date.distantFuture))

        return try await getDataTestHelper(
            router: router,
            expectedRequest: expectedRequest
        )
    }

    func testRefreshToken() async throws {
        let router: BaseAPIRouter<String, String> = Self.mockRouter(authType: .bearer(.refreshToken))
        let expectedRequest = try router.asURLRequest().withBearerToken("best-refresh-Token")
        
        tokenRepository.apiToken.store(.init(accessToken: "best-access-Token", refreshToken: "best-refresh-Token", expiration: Date.distantFuture))

        return try await getDataTestHelper(
            router: router,
            expectedRequest: expectedRequest
        )
    }

    func testRetryOnFailure() async throws {
        let router: BaseAPIRouter<String, String> = Self.mockRouter(authType: .bearer(.accessToken))
        tokenRepository.apiToken.store(.init(accessToken: "best-access-Token", refreshToken: "best-refresh-Token", expiration: Date.distantFuture))
        let expectedInitialRequest = self.setBearerTokenHelper(urlRequest: try router.asURLRequest(), token: "best-access-Token")
        let receivedInitialResponse = HTTPURLResponse(url: expectedInitialRequest.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!

        let refreshToken = "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiI4ZmZiYWJjOS1mMTc5LTQyMmEtYWQ1My0yYWQ3YmQzOTk0YTEiLCJleHAiOjE2NzU3ODU0MjAsImlzcyI6ImNvbS5kcm9ucHJvLm1haW5hcGkiLCJ0eXBlIjoiUkVGUkVTSCJ9.u87LWGKaCecebc8qS2m37KJG8kT0bVBjBIo1RuuRGMkIpg3Dss4Y_VgNz-k5r2iB1JoDtLUwh1huR9m0vptzHw"
        let accessToken = "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiI4ZmZiYWJjOS1mMTc5LTQyMmEtYWQ1My0yYWQ3YmQzOTk0YTEiLCJleHAiOjE2NzU3ODI3MjAsImlzcyI6ImNvbS5kcm9ucHJvLm1haW5hcGkiLCJ0eXBlIjoiQUNDRVNTIn0.7OjvRrOZgc8EuCjtOzdUPBZTKhhxm3m5p5oTxryjfPbUdjDAGq5X8HoyN2YFA_UQNRxSb6LLsujTxDEnsnvifQ"

        let refreshResponse = """
        {
            "refresh" : "\(refreshToken)",
            "expiresInS" : 900,
            "access" : "\(accessToken)"
        }
        """.data(using: .utf8)!

        let tokenResponse = try! JSONDecoder().decode(BaseAPIToken.self, from: refreshResponse)
        
        let expectedPostRefreshRequest = self.setBearerTokenHelper(urlRequest: try router.asURLRequest(), token: accessToken)

        let expectedResponse = "Hello, World!"
        let responseData = try JSONEncoder().encode(expectedResponse)

        let successfulRequest = XCTestExpectation(description: "Request should succeed after token refreshing")

        // Simulate a failure response for the initial request
        let failedRequest = XCTestExpectation(description: "Initial request should fail")
        onNetworkCall = { request in
            print(request.cURL(pretty: true), expectedInitialRequest.cURL(pretty: true))
            XCTAssertEqual(request, expectedInitialRequest)
            failedRequest.fulfill()

            self.onNetworkCall = { request in
                
                self.onNetworkCall = { request in
                    XCTAssertEqual(request, expectedPostRefreshRequest)
                    successfulRequest.fulfill()
                    return (try! JSONEncoder().encode(expectedResponse), HTTPURLResponse())
                }
                
                return (refreshResponse, HTTPURLResponse())

            }
            
            return (Data(), receivedInitialResponse)
        }
    
        // Perform the data request, which should trigger token refreshing and retry the request
        let response = try await apiService.getData(from: router)

        // Ensure that the request was retried and succeeded
        XCTAssertEqual(response, expectedResponse)
        XCTAssertEqual(delegate.receivedData, responseData)
        XCTAssertEqual(delegate.firedRequest, expectedPostRefreshRequest)
        XCTAssertNotNil(delegate.decodedValue as? String)

        // Wait for expectations to be fulfilled
        wait(for: [failedRequest, successfulRequest], timeout: 1)

        do {
            let accessToken = try await tokenManager.getAccessToken(forceRefresh: false)
            let refreshToken = try await tokenManager.getRefreshToken()

            XCTAssertEqual(accessToken, tokenResponse.accessToken)
            XCTAssertEqual(refreshToken, tokenResponse.refreshToken)
            XCTAssertEqual(tokenRepository.apiToken.value, tokenResponse)
        } catch {
            print(error)
            XCTFail()
        }
    }

    func testAccessTokenBeingRefreshed() async throws {
        let router: BaseAPIRouter<String, String> = Self.mockRouter(authType: .bearer(.accessToken))
        let expectedResponse = "Hello, World!"
        let responseData = try JSONEncoder().encode(expectedResponse)

        tokenRepository.apiToken.store(.init(accessToken: "best-access-Token", refreshToken: "best-refresh-Token", expiration: Date.distantPast))

        let refreshToken = "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiI4ZmZiYWJjOS1mMTc5LTQyMmEtYWQ1My0yYWQ3YmQzOTk0YTEiLCJleHAiOjE2NzU3ODU0MjAsImlzcyI6ImNvbS5kcm9ucHJvLm1haW5hcGkiLCJ0eXBlIjoiUkVGUkVTSCJ9.u87LWGKaCecebc8qS2m37KJG8kT0bVBjBIo1RuuRGMkIpg3Dss4Y_VgNz-k5r2iB1JoDtLUwh1huR9m0vptzHw"
        let accessToken = "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiI4ZmZiYWJjOS1mMTc5LTQyMmEtYWQ1My0yYWQ3YmQzOTk0YTEiLCJleHAiOjE2NzU3ODI3MjAsImlzcyI6ImNvbS5kcm9ucHJvLm1haW5hcGkiLCJ0eXBlIjoiQUNDRVNTIn0.7OjvRrOZgc8EuCjtOzdUPBZTKhhxm3m5p5oTxryjfPbUdjDAGq5X8HoyN2YFA_UQNRxSb6LLsujTxDEnsnvifQ"

        let refreshResponse = """
        {
            "refresh" : "\(refreshToken)",
            "expiresInS" : 900,
            "access" : "\(accessToken)"
        }
        """.data(using: .utf8)!

        let tokenResponse = try! JSONDecoder().decode(BaseAPIToken.self, from: refreshResponse)

        let expectation = XCTestExpectation(description: "TokenManager should try to refresh token")
        let expectedRequest = self.setBearerTokenHelper(urlRequest: try router.asURLRequest(), token: accessToken)
        let receivedResponse = HTTPURLResponse(url: expectedRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!

        var isRefreshTokenNetworkCall = true
        
        onNetworkCall = { request in
            if isRefreshTokenNetworkCall {
                expectation.fulfill()
                isRefreshTokenNetworkCall = false
                return (refreshResponse, HTTPURLResponse())
            } else {
                XCTAssertEqual(request, expectedRequest)
                return (responseData, receivedResponse)
            }
        }

        let response = try await apiService.getData(from: router)

        XCTAssertEqual(response, expectedResponse)
        XCTAssertEqual(delegate.receivedData, responseData)
        XCTAssertEqual(delegate.receivedResponse, receivedResponse)
        XCTAssertEqual(delegate.firedRequest, expectedRequest)
        XCTAssertNotNil(delegate.decodedValue as? String)

        do {
            let accessToken = try await tokenManager.getAccessToken(forceRefresh: false)
            let refreshToken = try await tokenManager.getRefreshToken()

            XCTAssertEqual(accessToken, tokenResponse.accessToken)
            XCTAssertEqual(refreshToken, tokenResponse.refreshToken)
            XCTAssertEqual(tokenRepository.apiToken.value, tokenResponse)
        } catch {
            print(error)
            XCTFail()
        }
    }

    override func setBearerTokenHelper(urlRequest: URLRequest, token: String) -> URLRequest {
        urlRequest.withBearerToken(token)
    }
}
