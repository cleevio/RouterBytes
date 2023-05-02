//
//  APITokenTests.swift
//  
//
//  Created by Lukáš Valenta on 02.05.2023.
//

import XCTest
import CleevioAuthentication

final class ApiTokenTests: XCTestCase {
    func testAccessTokenExpiresNow() {
        let now = Date()
        let expirationDate = now
        let apitoken = BaseAPIToken(accessToken: "", refreshToken: "", expiration: expirationDate)
        
        let expectedValue = true
        XCTAssertEqual(apitoken.needsToBeRefreshed(currentDate: now), expectedValue)
    }
    
    func testAccessTokenExpiresNowInAMinute() {
        let now = Date()
        let expirationDate = now.addingTimeInterval(60)
        let apitoken = BaseAPIToken(accessToken: "", refreshToken: "", expiration: expirationDate)
        
        let expectedValue = true
        XCTAssertEqual(apitoken.needsToBeRefreshed(currentDate: now), expectedValue)
    }
    
    func testAccessTokenExpired() {
        let now = Date()
        let expirationDate = now.addingTimeInterval(-60)
        let apitoken = BaseAPIToken(accessToken: "", refreshToken: "", expiration: expirationDate)
        
        let expectedValue = true
        XCTAssertEqual(apitoken.needsToBeRefreshed(currentDate: now), expectedValue)
    }
    
    func testAccessTokenExpiredInDistantPast() {
        let now = Date()
        let expirationDate = Date.distantPast
        let apitoken = BaseAPIToken(accessToken: "", refreshToken: "", expiration: expirationDate)
        
        let expectedValue = true
        XCTAssertEqual(apitoken.needsToBeRefreshed(currentDate: now), expectedValue)
    }
    
    func testAccessTokenExpiresNowIn299Seconds() {
        let now = Date()
        let expirationDate = now.addingTimeInterval(299)
        let apitoken = BaseAPIToken(accessToken: "", refreshToken: "", expiration: expirationDate)
        
        let expectedValue = true
        XCTAssertEqual(apitoken.needsToBeRefreshed(currentDate: now), expectedValue)
    }
    
    func testAccessTokenExpiresNowIn5Minutes() {
        let now = Date()
        let expirationDate = now.addingTimeInterval(300)
        let apitoken = BaseAPIToken(accessToken: "", refreshToken: "", expiration: expirationDate)
        
        let expectedValue = false
        XCTAssertEqual(apitoken.needsToBeRefreshed(currentDate: now), expectedValue)
    }
    
    func testAccessTokenExpiresNowIn10Minutes() {
        let now = Date()
        let expirationDate = now.addingTimeInterval(600)
        let apitoken = BaseAPIToken(accessToken: "", refreshToken: "", expiration: expirationDate)
        
        let expectedValue = false
        XCTAssertEqual(apitoken.needsToBeRefreshed(currentDate: now), expectedValue)
    }
    
    func testAccessTokenExpiresNowInDistantFuture() {
        let now = Date()
        let expirationDate = Date.distantFuture
        let apitoken = BaseAPIToken(accessToken: "", refreshToken: "", expiration: expirationDate)
        
        let expectedValue = false
        XCTAssertEqual(apitoken.needsToBeRefreshed(currentDate: now), expectedValue)
    }
    
    func testAccessTokenExpiresNowWithThreshold() {
        let now = Date()
        let expirationDate = now
        let apitoken = BaseAPIToken(accessToken: "", refreshToken: "", expiration: expirationDate)
        
        let expectedValue = true
        XCTAssertEqual(apitoken.needsToBeRefreshed(currentDate: now, maximumTimeUntilExpiration: 60), expectedValue)
    }
    
    func testAccessTokenExpiresNowInAMinuteWithThreshold() {
        let now = Date()
        let expirationDate = now.addingTimeInterval(60)
        let apitoken = BaseAPIToken(accessToken: "", refreshToken: "", expiration: expirationDate)
        
        let expectedValue = true
        XCTAssertEqual(apitoken.needsToBeRefreshed(currentDate: now, maximumTimeUntilExpiration: 65), expectedValue)
    }
    
    func testAccessTokenExpiredWithThreshold() {
        let now = Date()
        let expirationDate = now.addingTimeInterval(-60)
        let apitoken = BaseAPIToken(accessToken: "", refreshToken: "", expiration: expirationDate)
        
        let expectedValue = true
        XCTAssertEqual(apitoken.needsToBeRefreshed(currentDate: now, maximumTimeUntilExpiration: 60), expectedValue)
    }
    
    func testAccessTokenExpiredInDistantPastWithThreshold() {
        let now = Date()
        let expirationDate = Date.distantPast
        let apitoken = BaseAPIToken(accessToken: "", refreshToken: "", expiration: expirationDate)
        
        let expectedValue = true
        XCTAssertEqual(apitoken.needsToBeRefreshed(currentDate: now, maximumTimeUntilExpiration: 60), expectedValue)
    }
    
    func testAccessTokenExpiresNowIn299SecondsWithThreshold() {
        let now = Date()
        let expirationDate = now.addingTimeInterval(299)
        let apitoken = BaseAPIToken(accessToken: "", refreshToken: "", expiration: expirationDate)
        
        let expectedValue = true
        XCTAssertEqual(apitoken.needsToBeRefreshed(currentDate: now, maximumTimeUntilExpiration: 300), expectedValue)
    }
    
    func testAccessTokenExpiresNowIn5MinutesWithThreshold() {
        let now = Date()
        let expirationDate = now.addingTimeInterval(300)
        let apitoken = BaseAPIToken(accessToken: "", refreshToken: "", expiration: expirationDate)
        
        let expectedValue = false
        XCTAssertEqual(apitoken.needsToBeRefreshed(currentDate: now, maximumTimeUntilExpiration: 300), expectedValue)
    }
    
    func testAccessTokenExpiresNowIn10MinutesWithThreshold() {
        let now = Date()
        let expirationDate = now.addingTimeInterval(600)
        let apitoken = BaseAPIToken(accessToken: "", refreshToken: "", expiration: expirationDate)
        
        let expectedValue = false
        XCTAssertEqual(apitoken.needsToBeRefreshed(currentDate: now, maximumTimeUntilExpiration: 300), expectedValue)
    }
    
    func testAccessTokenExpiresNowInDistantFutureWithThreshold() {
        let now = Date()
        let expirationDate = Date.distantFuture
        let apitoken = BaseAPIToken(accessToken: "", refreshToken: "", expiration: expirationDate)
        
        let expectedValue = false
        XCTAssertEqual(apitoken.needsToBeRefreshed(currentDate: now, maximumTimeUntilExpiration: 300), expectedValue)
    }
}
