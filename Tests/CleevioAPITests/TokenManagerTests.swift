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
open class TokenManagerTestCase<AuthorizationType: APITokenAuthorizationType>: XCTestCase {
    var sut: TokenManager<AuthorizationType, BaseAPIToken, RefreshTokenRouter, DateProviderMock, NetworkingServiceMock, MockURLRequestProvider<AuthorizationType>, MockURLRequestProvider<AuthorizationType>, APITokenRepositoryMock<BaseAPIToken>>!
    var tokenRepository: APITokenRepositoryMock<BaseAPIToken>!
    var hostnameProvider: HostnameProvider { urlRequestProvider }
    var urlRequestProvider: MockURLRequestProvider<AuthorizationType>!
    public var onRefreshNetworkCall: ((URLRequest) -> (Data, URLResponse))!
    
    override open func setUp() {
        dateProvider = .init(date: Date())
        let networkingService = NetworkingServiceMock(onDataCall: { request, _ in
            self.onRefreshNetworkCall(request)
        })
        
        tokenRepository = APITokenRepositoryMock(apiToken: nil)
        
        onRefreshNetworkCall = { _ in
            XCTFail("Refresh token action should not be called")
            fatalError()
        }
        
        self.urlRequestProvider = MockURLRequestProvider(hostname: URL(string: "https://cleevio.com")!)
        
        sut = TokenManager(
            apiService: APIService(networkingService: networkingService, urlRequestProvider: urlRequestProvider),
            dateProvider: dateProvider,
            apiTokenRepository: tokenRepository,
            hostnameProvider: urlRequestProvider
        )
    }
    
    func setLoggedIn(expiration: Date = Date.distantFuture) {
        tokenRepository.apiToken.store(.init(
            accessToken: UUID().uuidString,
            refreshToken: UUID().uuidString,
            expiration: expiration
        ))
    }

    func refreshingHelper(signedInTokenExpiration: Date,
                          forceRefresh: Bool,
                          executeBeforeCheck: (() async throws -> Void)? = nil) async throws {
        setLoggedIn(expiration: signedInTokenExpiration)
        
        let accessToken: String = "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiI4ZmZiYWJjOS1mMTc5LTQyMmEtYWQ1My0yYWQ3YmQzOTk0YTEiLCJleHAiOjE2NzU3ODI3MjAsImlzcyI6ImNvbS5kcm9ucHJvLm1haW5hcGkiLCJ0eXBlIjoiQUNDRVNTIn0.7OjvRrOZgc8EuCjtOzdUPBZTKhhxm3m5p5oTxryjfPbUdjDAGq5X8HoyN2YFA_UQNRxSb6LLsujTxDEnsnvifQ"

        let refreshToken = "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiI4ZmZiYWJjOS1mMTc5LTQyMmEtYWQ1My0yYWQ3YmQzOTk0YTEiLCJleHAiOjE2NzU3ODU0MjAsImlzcyI6ImNvbS5kcm9ucHJvLm1haW5hcGkiLCJ0eXBlIjoiUkVGUkVTSCJ9.u87LWGKaCecebc8qS2m37KJG8kT0bVBjBIo1RuuRGMkIpg3Dss4Y_VgNz-k5r2iB1JoDtLUwh1huR9m0vptzHw"

        let refreshResponse = """
        {
            "refreshParameter" : "\(refreshToken)",
            "expiresInSParameter" : 900,
            "accessParameter" : "\(accessToken)"
        }
        """.data(using: .utf8)!

        let tokenResponse = try! JSONDecoder().decode(BaseAPIToken.self, from: refreshResponse)

        let expectation = XCTestExpectation(description: "TokenManager should try to refresh token")

        let refreshRouter = RefreshTokenRouter()
        let expectedRefreshURLRequest = try refreshRouter
            .asURLRequest(hostname: hostnameProvider.hostname(for: refreshRouter))
            .withBearerToken(tokenRepository.apiToken.value!.refreshToken.description)
        
        onRefreshNetworkCall = { request in
            XCTAssertEqual(expectedRefreshURLRequest, request)
            expectation.fulfill()
            return (refreshResponse, HTTPURLResponse())
        }
        
        try await executeBeforeCheck?()

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
}
    
@available(iOS 15.0, *)
final class TokenManagerTests: TokenManagerTestCase<AuthorizationType> {
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
}

@available(iOS 15.0, *)
final class TokenManagerURLRequestProviderTests: TokenManagerTestCase<CleevioAPI.AuthorizationType> {
    func testRefreshOnError() async throws {
        try await refreshingHelper(signedInTokenExpiration: Date.distantFuture, forceRefresh: false) {
            let router = Self.mockRouter(type: .none)
            let request = try await self.sut.getURLRequestOnUnAuthorizedError(from: router)
            XCTAssertEqual(request, try router.asURLRequest(hostname: self.hostnameProvider.hostname(for: router)))
        }
    }

    func testURLRequestProvidingWithNoneAuthType() async throws {
        let router = Self.mockRouter(type: .none)
        let request = try await self.sut.getURLRequest(from: router)
        XCTAssertEqual(request, try router.asURLRequest(hostname: self.hostnameProvider.hostname(for: router)))
    }

    func testRefreshTokenOnURLRequest() async throws {
        try await refreshingHelper(signedInTokenExpiration: Date.distantFuture, forceRefresh: false) {
            let router = Self.mockRouter(type: .bearer(.accessToken))
            let request = try await self.sut.getURLRequestOnUnAuthorizedError(from: router)
            XCTAssertEqual(request, try router.asURLRequest(hostname: self.hostnameProvider.hostname(for: router)).withBearerToken(self.tokenRepository.apiToken.value!.accessToken))
        }
    }

    func testURLRequestProvidingWithAccessTokenAuthType() async throws {
        self.setLoggedIn(expiration: .distantFuture)
        let router = Self.mockRouter(type: .bearer(.accessToken))
        let request = try await self.sut.getURLRequest(from: router)
        XCTAssertEqual(request, try router.asURLRequest(hostname: self.hostnameProvider.hostname(for: router)).withBearerToken(tokenRepository.apiToken.value!.accessToken))
    }

    func testURLRequestProvidingWithAccessTokenNotLoggedIn() async throws {
        let router = Self.mockRouter(type: .bearer(.accessToken))
        do {
            _ = try await self.sut.getURLRequest(from: router)
            XCTFail("Error not thrown")
        } catch TokenManagerError.notLoggedIn {
            
        } catch {
            XCTFail("Wrong password thrown: \(error)")
        }
    }

    func testURLRequestProvidingWithRefreshTokenLoggedIn() async throws {
        self.setLoggedIn(expiration: .distantFuture)
        let router = Self.mockRouter(type: .bearer(.refreshToken))
        let request = try await self.sut.getURLRequest(from: router)
        XCTAssertEqual(request, try router.asURLRequest(hostname: self.hostnameProvider.hostname(for: router)).withBearerToken(tokenRepository.apiToken.value!.refreshToken))
    }

    func testURLRequestProvidingWithRefreshTokenNotLoggedIn() async throws {
        let router = Self.mockRouter(type: .bearer(.refreshToken))
        do {
            _ = try await self.sut.getURLRequest(from: router)
            XCTFail("Error not thrown")
        } catch TokenManagerError.notLoggedIn {
            
        } catch {
            XCTFail("Wrong password thrown: \(error)")
        }
    }

    static private func mockRouter(type: AuthorizationType) -> BaseAPIRouter<String, String> {
        BaseAPIRouter(hostname: URL(string: "https://cleevio.com")!, path: "/blog", authType: type)
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

struct RefreshTokenRouter: APIRouter {
    struct Response: TokenAPIRouterResponse {
        let refreshParameter: String
        let expiresInSParameter: TimeInterval
        let accessParameter: String

        func asAPIToken() -> CleevioAuthentication.BaseAPIToken {
            BaseAPIToken(
                accessToken: accessParameter,
                refreshToken: refreshParameter,
                expiration: dateProvider.currentDate().addingTimeInterval(expiresInSParameter))
        }
    }

    var defaultHeaders: CleevioAPI.Headers { [:] }
    var hostname: URL { URL(string: "https://cleevio.com")! }
    var jsonDecoder: JSONDecoder = .init()
    var jsonEncoder: JSONEncoder = .init()
    var path: String { "" }
    var authType: CleevioAPI.AuthorizationType { .bearer(.refreshToken) }
}

extension RefreshTokenRouter: RefreshTokenAPIRouter {
    typealias APIToken = BaseAPIToken

    init(previousToken: BaseAPIToken) {
        self.init()
    }
}
