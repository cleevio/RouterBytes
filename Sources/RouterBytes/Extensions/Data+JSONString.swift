//
//  Data+JSONString.swift
//  
//
//  Created by Lukáš Valenta on 30.04.2023.
//

import Foundation

public extension Data {
    /**
     Returns a JSON string representation of the Data object if it contains valid JSON. If `pretty` is set to `true`, the JSON string will be formatted with whitespace for better readability. The encoding of the resulting string can be specified using the `encoding` parameter.
     
     - Parameters:
        - pretty: A Boolean value indicating whether to format the resulting JSON string with whitespace for readability.
        - encoding: The encoding to use for the resulting string. The default is UTF-8.
     
     - Returns: A JSON string representation of the Data object if it contains valid JSON, or the original string encoding if not. Returns `nil` if the JSON serialization fails.
     */
    func asJSONString(pretty: Bool, encoding: String.Encoding = .utf8) -> String? {
        guard pretty,
              let json = try? JSONSerialization.jsonObject(with: self),
              let prettyJSON = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
              let prettyJSONString = String(data: prettyJSON, encoding: encoding)
        else { return String(data: self, encoding: encoding) }
        
        return prettyJSONString
    }
}
