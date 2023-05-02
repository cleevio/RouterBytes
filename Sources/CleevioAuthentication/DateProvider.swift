//
//  DateProvider.swift
//  
//
//  Created by Lukáš Valenta on 02.05.2023.
//

import Foundation

/**
 A type that provides the current date.

 Types conforming to this protocol can be used to abstract away the system's date
 functions and instead provide a mock date for testing purposes.
 */
public protocol DateProviderType {
    /**
     Returns the current date.
     
     - Returns: The current `Date`.
     */
    func currentDate() -> Date
}

/**
 A concrete implementation of `DateProviderType` that returns the system's current date.
 */
public struct DateProvider: DateProviderType {
    @inlinable
    public func currentDate() -> Date {
        Date()
    }
}

/**
 A mock implementation of `DateProviderType` that returns a fixed date for testing purposes.
 */
public struct DateProviderMock: DateProviderType {
    /**
     The fixed date that will be returned by the `currentDate()` function.
     */
    public let date: Date

    /**
     Creates a new `DateProviderMock` instance with the given fixed date.
     
     - Parameter date: The fixed date to be returned by the `currentDate()` function.
     */
    @inlinable
    public init(date: Date) {
        self.date = date
    }

    @inlinable
    public func currentDate() -> Date {
        date
    }
}

