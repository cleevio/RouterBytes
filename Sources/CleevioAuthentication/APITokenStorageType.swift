//
//  APITokenStorageType.swift
//  
//
//  Created by Lukáš Valenta on 13.08.2023.
//

import Foundation
import CleevioStorage
import CleevioAPI

/// A protocol that defines necessary interface an APIToken storage needs to implement to work with TokenManager
public protocol APITokenStorageType<APIToken> {
    /// The type of API token to be stored in the storage.
    associatedtype APIToken: CodableAPITokentType

    var apiToken: APIToken? { get }

    var isUserLoggedIn: Bool { get }

    func storeAPIToken(_ apiToken: APIToken) async throws

    func removeAPITokenFromStorage() async
}

// TODO: Make it work so that storeAPIToken is not in APITokenStorageType
public protocol SettableAPITokenStorageType: APITokenStorageType {
//func storeAPIToken(_ apiToken: APIToken) async throws
}
