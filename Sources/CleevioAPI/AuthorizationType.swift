//
//  AuthorizationType.swift
//  
//
//  Created by Lukáš Valenta on 28.04.2023.
//

import Foundation

/// The type of authorization used for a network request.
public enum AuthorizationType {
    
    /// No authorization used for the request.
    case none
    
    /// Bearer authorization used for the request.
    case bearer(BearerType)
    
    /// The type of bearer authorization used for the request.
    public enum BearerType {
        
        /// Access token used for bearer authorization.
        case accessToken
        
        /// Refresh token used for bearer authorization.
        case refreshToken
    }
}
