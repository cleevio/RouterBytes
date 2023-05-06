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
final class AuthorizationTypeTokenAPIServiceTests: XCTestCase {
    var networkingService: NetworkingServiceMock!
    var apiService: AuthorizationTypeTokenAPIService<BaseAPIToken, TokenManager<BaseAPIToken, RefreshTokenRouter>>!
    var tokenManager: TokenManager<BaseAPIToken, RefreshTokenRouter>!
    var delegate: MockAPIServiceEventDelegate!
    var onNetworkCall: ((URLRequest) -> (Data, URLResponse))!
    var tokenRepository: APITokenRepositoryMock<BaseAPIToken>!
    
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

        apiService = AuthorizationTypeTokenAPIService(tokenManager: tokenManager, networkingService: networkingService)
        delegate = MockAPIServiceEventDelegate()
        apiService.eventDelegate = delegate
    }
    
    override func tearDown() {
        networkingService = nil
        apiService = nil
        delegate = nil
        super.tearDown()
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
        let expectedRequest = try router.asURLRequest().withBearerToken(accessToken)
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

    static private func mockRouter<Response: Decodable>(authType: AuthorizationType) -> BaseAPIRouter<String, Response> {
        BaseAPIRouter(hostname: URL(string: "https://cleevio.com")!, path: "/blog", authType: authType)
    }
}
