//
//  FormMultipart.swift
//
//
//  Created by Lukáš Valenta on 11.02.2024.
//

import Foundation
import CleevioAPI

public struct FormMultipart: Sendable, Hashable {
    public var boundary: String
    public var parts: [Part]
    public var kind: Kind

    @inlinable
    public init(parts: [Part] = [], boundary: String = UUID().uuidString, kind: Kind = .formData) {
        self.parts = parts
        self.boundary = boundary
        self.kind = kind
    }

    public enum Kind: String, Sendable, Hashable {
        case formData = "form-data"
        case mixed = "mixed"
    }

    public struct Part: Sendable, Hashable {
        public var mimeType: MIMEType?
        public var contentDisposition: String
        public var name: String
        public var fileName: String?
        public var data: Data

        public init(mimeType: MIMEType? = nil, contentDisposition: String = "form-data", name: String, fileName: String? = nil, data: Data) {
            self.mimeType = mimeType
            self.contentDisposition = contentDisposition
            self.name = name
            self.fileName = fileName
            self.data = data
        }

        public struct MIMEType: RawRepresentable, Sendable, Hashable, ExpressibleByStringLiteral {
            public var rawValue: String

            public init(rawValue: String) {
                self.rawValue = rawValue
            }

            public init(stringLiteral value: StringLiteralType) {
                self.init(rawValue: value)
            }

            public static let textPlain: MIMEType = "text/plain"
            public static let textHtml: MIMEType = "text/html"
            public static let textCss: MIMEType = "text/css"
            public static let textJavascript: MIMEType = "text/javascript"

            public static let imageGif: MIMEType = "image/gif"
            public static let imagePng: MIMEType = "image/png"
            public static let imageJpeg: MIMEType = "image/jpeg"
            public static let imageBmp: MIMEType = "image/bmp"
            public static let imageWebp: MIMEType = "image/webp"
            public static let imageSvgXml: MIMEType = "image/svg+xml"

            public static let audioMidi: MIMEType = "audio/midi"
            public static let audioMpeg: MIMEType = "audio/mpeg"
            public static let audioWebm: MIMEType = "audio/webm"
            public static let audioOgg: MIMEType = "audio/ogg"
            public static let audioWav: MIMEType = "audio/wav"

            public static let videoWebm: MIMEType = "video/webm"
            public static let videoOgg: MIMEType = "video/ogg"
        }
    }

    public func asData() -> Data {
        let openedBoundary = "--\(boundary)"
        let newLineString = "\r\n"
        let newLine = newLineString.asLossyConvertedData()!
        let openingBoundaryWithNewLine = "\(openedBoundary)\(newLineString)".asLossyConvertedData()!
        var data = Data()

        for part in parts {
            data.append(openingBoundaryWithNewLine)

            data.append("Content-Disposition: \(part.contentDisposition); name=\"\(part.name)\"")

            if let fileName = part.fileName?.replacingOccurrences(of: "\"", with: "_") {
                data.append("; filename=\"\(fileName)\"")
            }

            data.append(newLine)

            if let mimeType = part.mimeType {
                data.append("Content-Type: \(mimeType.rawValue)")
                data.append(newLine)
            }

            data.append(newLine)
            data.append(part.data)
            data.append(newLine)
        }
        
        data.append("\(openedBoundary)--")
        return data
    }
}

public extension APIRouter where RequestBody == FormMultipart {
    @inlinable
    func encode(_ value: RequestBody) throws -> Data? {
        value.asData()
    }

    @inlinable
    func contentType(from body: RequestBody) -> ContentType {
        .formMultipart(kind: body.kind, boundary: body.boundary)
    }
}

public extension ContentType {
    @inlinable
    static func formMultipart(kind: FormMultipart.Kind, boundary: String) -> Self {
        .init(rawValue: "multipart/\(kind.rawValue); boundary=\(boundary)")
    }
}

extension Data {
    mutating func append(_ string: String) {
        self.append(string.asLossyConvertedData()!)
    }
}

extension String {
    func asLossyConvertedData(encoding: String.Encoding = .utf8) -> Data? {
        data(using: encoding, allowLossyConversion: true)
    }
}
