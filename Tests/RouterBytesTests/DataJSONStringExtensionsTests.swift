//
//  DataJSONStringExtensionsTests.swift
//  
//
//  Created by Lukáš Valenta on 30.04.2023.
//

import Foundation
import RouterBytes
import XCTest

class DataJSONStringExtensionsTests: XCTestCase {
    func testAsJSONStringWithPrettyOption() {
        let jsonString = "{\"name\":\"John Doe\",\"age\":30}"
        let data = jsonString.data(using: .utf8)!
        let expectedPrettyJSONString = "{\n  \"name\" : \"John Doe\",\n  \"age\" : 30\n}"
        
        let prettyJSONString = data.asJSONString(pretty: true)
        XCTAssertEqual(prettyJSONString, expectedPrettyJSONString)
    }
    
    func testAsJSONStringWithoutPrettyOption() {
        let jsonString = "{\"name\":\"John Doe\",\"age\":30}"
        let data = jsonString.data(using: .utf8)!
        
        let jsonStringFromData = data.asJSONString(pretty: false)
        XCTAssertEqual(jsonStringFromData, jsonString)
    }
    
    func testAsJSONStringWithEmptyData() {
        let data = Data()
        let jsonStringFromData = data.asJSONString(pretty: true)
        XCTAssertEqual(jsonStringFromData, "")
    }
}
