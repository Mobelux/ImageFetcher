//
//  Networking.swift
//  Mobelux
//
//  MIT License
//
//  Copyright (c) 2022 Mobelux LLC
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

/// A simple wrapper for a closure performing an async network request.
public struct Networking {
    /// Downloads the contents of a URL based on the specified URL request and delivers the data asynchronously.
    public let load: (URLRequest) async throws -> Data

    /// Creates a wrapper to perform async network requests.
    /// - Parameter load: A closure to load a request.
    public init(load: @escaping (URLRequest) async throws -> Data) {
        self.load = load
    }
}

public extension Networking {

    /// A type that validates network responses.
    enum ResponseValidator {
        /// Throws an error if the given response was not successful.
        /// - Parameter response: The response to validate.
        public static func validate(_ response: URLResponse) throws {
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ImageError.cannotParse
            }

            switch httpResponse.statusCode {
            case 200 ..< 300: return
            default: throw ImageError.cannotParse
            }
        }
    }

    /// Creates a network request wrapper with the specified session configuration.
    /// - Parameters:
    ///   - configuration: A configuration object that specifies certain behaviors, such as caching policies, timeouts, proxies, pipelining, TLS versions to support, cookie policies, credential storage, and so on.
    ///   - validateResponse: A closure that throws an error if the response passed to it was not successful.
    init(
        _ configuration: URLSessionConfiguration = .default,
        validateResponse: @escaping (URLResponse) throws -> Void = ResponseValidator.validate
    ) {
        let session = URLSession(configuration: configuration)
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            self.load = { request in
                let (data, response) = try await session.data(for: request)
                try validateResponse(response)
                return data
            }

        } else {
            self.load = { request in
                let (data, response) = try await session.data(for: request)
                try validateResponse(response)
                return data
            }
        }
    }
}
