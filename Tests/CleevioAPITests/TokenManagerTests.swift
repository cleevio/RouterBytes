//
//  TokenManagerTests.swift
//  
//
//  Created by Lukáš Valenta on 02.05.2023.
//

import XCTest
import CleevioAuthentication
import CleevioAPI

fileprivate var dateProvider = DateProviderMock(date: Date())

@available(iOS 15.0, *)
final class TokenManagerTests: XCTestCase {
    var sut: TokenManager<BaseAPIToken, RefreshTokenRouter>!
    private var tokenRepository: APITokenRepositoryMock<BaseAPIToken>!

    private var onRefreshNetworkCall: ((URLRequest) -> (Data, URLResponse))!

    override func setUp() {
        dateProvider = .init(date: Date())
        let networkingService = NetworkingServiceMock(onDataCall: { request, _ in
            self.onRefreshNetworkCall(request)
        })

        tokenRepository = APITokenRepositoryMock(apiToken: nil)

        onRefreshNetworkCall = { _ in
            XCTFail("Refresh token action should not be called")
            fatalError()
        }

        sut = TokenManager(
            apiService: APIService(networkingService: networkingService),
            dateProvider: dateProvider,
            apiTokenRepository: tokenRepository
        )
    }

    func testRefreshTokenNotLoggedIn() async {
        do {
            _ = try await sut.getRefreshToken()
            XCTFail("GetRefreshToken should throw an error")
        } catch {
            XCTAssertEqual(error as? TokenManagerError, TokenManagerError.notLoggedIn)
        }
    }

    func testAccessTokenNotLoggedIn() async {
        do {
            _ = try await sut.getAccessToken(forceRefresh: false)
            XCTFail("GetRefreshToken should throw an error")
        } catch {
            XCTAssertEqual(error as? TokenManagerError, TokenManagerError.notLoggedIn)
        }
    }

    func testRefreshTokenLoggedIn() async throws {
        setLoggedIn()
        let accessToken = try await sut.getRefreshToken()

        XCTAssertEqual(accessToken, tokenRepository.apiToken.value?.refreshToken)
    }

    func testAccessTokenLoggedIn() async throws {
        setLoggedIn()
        let accessToken = try await sut.getAccessToken(forceRefresh: false)

        XCTAssertEqual(accessToken, tokenRepository.apiToken.value?.accessToken)
    }

    func testApiTokenIsUpdatedAfterRefresh() async throws {
        try await refreshingHelper(signedInTokenExpiration: Date.distantFuture, forceRefresh: true)
    }

    func testAccessTokenIsRefreshedWhenExpired() async throws {
        try await refreshingHelper(signedInTokenExpiration: Date.distantPast, forceRefresh: false)
    }

    func testAccessTokenIsRefreshedWithMinuteToExpiration() async throws {
        try await refreshingHelper(signedInTokenExpiration: Date(timeIntervalSinceNow: 60), forceRefresh: false)
    }

    func refreshingHelper(signedInTokenExpiration: Date, forceRefresh: Bool) async throws {
        setLoggedIn(expiration: signedInTokenExpiration)

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

        onRefreshNetworkCall = { _ in
            expectation.fulfill()
            return (refreshResponse, HTTPURLResponse())
        }

        do {
            let accessToken = try await sut.getAccessToken(forceRefresh: forceRefresh)
            let refreshToken = try await sut.getRefreshToken()

            XCTAssertEqual(accessToken, tokenResponse.accessToken)
            XCTAssertEqual(refreshToken, tokenResponse.refreshToken)
            XCTAssertEqual(tokenRepository.apiToken.value, tokenResponse)
        } catch {
            print(error)
            XCTFail()
        }

        wait(for: [expectation], timeout: 0.1)
    }

    private func setLoggedIn(expiration: Date = Date.distantFuture) {
        tokenRepository.apiToken.store(.init(
            accessToken: UUID().uuidString,
            refreshToken: UUID().uuidString,
            expiration: expiration
        ))
    }
}

extension BaseAPIToken: Codable {
    enum CodingKeys: CodingKey {
        case access
        case refresh
        case expiresInS
    }

    public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        let expiresInSeconds = try container.decode(TimeInterval.self, forKey: .expiresInS)

        self.init(
            accessToken: try container.decode(String.self, forKey: CodingKeys.access),
            refreshToken: try container.decode(String.self, forKey: CodingKeys.refresh),
            expiration: dateProvider.currentDate().addingTimeInterval(expiresInSeconds)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .access)
        try container.encode(refreshToken, forKey: .refresh)
        try container.encode(expiration.timeIntervalSinceNow, forKey: .expiresInS)
    }
}

struct RefreshTokenRouter: RefreshTokenAPIRouter, APIRouter {
    typealias Response = BaseAPIToken

    var defaultHeaders: CleevioAPI.Headers { [:] }
    var hostname: URL { URL(string: "https://cleevio.com")! }
    var jsonDecoder: JSONDecoder = .init()
    var jsonEncoder: JSONEncoder = .init()
    var path: String { "" }
    var authType: CleevioAPI.AuthorizationType { .bearer(.refreshToken) }
}
