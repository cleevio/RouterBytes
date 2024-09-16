//
//  Path.swift
//
//
//  Created by Lukáš Valenta on 05.01.2024.
//

import Foundation

/// A type representing a path, composed of components, commonly used for working with file paths or URLs.
public struct Path: RawRepresentable, Hashable, Codable, Sendable {
    
    /// A single component of a path.
    public struct Component: RawRepresentable, Hashable, Codable, Sendable {
        /// The raw value of the path component.
        public let rawValue: String

        /// Initializes a path component with the given raw value, ensuring it is not empty.
        ///
        /// - Parameter rawValue: The raw value of the path component.
        /// - Returns: An initialized path component, or `nil` if the raw value is empty.
        @inlinable
        public init?(rawValue: String) {
            if rawValue.isEmpty {
                return nil
            }

            self.rawValue = rawValue
        }
    }

    /// The array of components that make up the path.
    public var components: [Path.Component]

    /// The raw value of the path, obtained by concatenating its components with a separator ("/").
    public var rawValue: String {
        components.reduce(into: "") { path, component in
            path += "\(path.isEmpty ? "" : "/")\(component)"
        }
    }

    /// Initializes a path with an array of string components.
    ///
    /// - Parameter components: An array of string components to form the path.
    @inlinable
    public init(components: [String]) {
        self.init(components: components.compactMap(Component.init(rawValue:)))
    }

    /// Initializes a path with an array of path components.
    ///
    /// - Parameter components: An array of path components.
    @inlinable
    public init(components: [Component] = []) {
        self.components = components
    }

    /// Initializes a path with a raw string value, splitting it into components using "/" as a separator.
    ///
    /// - Parameter rawValue: The raw string value representing the path.
    @inlinable
    public init(rawValue: String) {
        self.init(components: rawValue.components(separatedBy: "/"))
    }
}

/// Concatenates two paths, producing a new path.
///
/// - Parameters:
///   - lhs: The first path.
///   - rhs: The second path.
/// - Returns: A new path formed by concatenating the components of both paths.
@inlinable
public func +(lhs: Path, rhs: Path) -> Path {
    var components = lhs.components
    components.append(contentsOf: rhs.components)

    return Path(components: components)
}

/// Concatenates two paths, producing a new path.
///
/// - Parameters:
///   - lhs: The first path.
///   - rhs: Second path component.
/// - Returns: A new path formed by concatenating the components of both paths.
@inlinable
public func +(lhs: Path, rhs: String) -> Path {
    lhs + Path(rawValue: rhs)
}

/// Concatenates two paths, producing a new path.
///
/// - Parameters:
///   - lhs: The first path.
///   - rhs: Second path component.
/// - Returns: A new path formed by concatenating the components of both paths.
@inlinable
@_disfavoredOverload
public func +(lhs: String, rhs: Path) -> Path {
    Path(rawValue: lhs) + rhs
}

/// Concatenates two paths, producing a new path.
///
/// - Parameters:
///   - lhs: The first path.
///   - rhs: Second path component.
/// - Returns: A new path formed by concatenating the components of both paths.
@inlinable
public func +(lhs: Path, rhs: UUID) -> Path {
    lhs + Path(rawValue: rhs.uuidString)
}

/// Concatenates two paths, producing a new path.
///
/// - Parameters:
///   - lhs: The first path.
///   - rhs: Second path component.
/// - Returns: A new path formed by concatenating the components of both paths.
@inlinable
@_disfavoredOverload
public func +(lhs: UUID, rhs: Path) -> Path {
    Path(rawValue: lhs.uuidString) + rhs
}

/// Concatenates two paths in place, modifying the first path.
///
/// - Parameters:
///   - lhs: The first path.
///   - rhs: The second path.
public func +=(lhs: inout Path, rhs: Path) {
    lhs.components.append(contentsOf: rhs.components)
}


/// Enables initialization of a path using a string literal.
extension Path: ExpressibleByStringLiteral {
    @inlinable
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

/// Enables string interpolation for paths.
extension Path: ExpressibleByStringInterpolation { }

/// Extends the `String` type to allow string interpolation with path and path component values.
public extension String {
    /// Appends the raw value of a path to the string.
    ///
    /// - Parameter value: The path to be appended.
    @inlinable
    mutating func appendInterpolation(_ value: Path) {
        append(value.rawValue)
    }

    /// Appends the raw value of a path component to the string.
    ///
    /// - Parameter value: The path component to be appended.
    @inlinable
    mutating func appendInterpolation(_ value: Path.Component) {
        append(value.rawValue)
    }
}

/// Conforms `Path` to the `CustomStringConvertible` protocol, providing a textual representation of the path.
extension Path: CustomStringConvertible {
    /// A textual representation of the path.
    @inlinable
    public var description: String { rawValue }
}

/// Conforms `Path.Component` to the `CustomStringConvertible` protocol, providing a textual representation of the path component.
extension Path.Component: CustomStringConvertible {
    /// A textual representation of the path component.
    @inlinable
    public var description: String { rawValue }
}
