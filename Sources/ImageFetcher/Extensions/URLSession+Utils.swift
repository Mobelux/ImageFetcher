//
//  URLSession+Utils.swift
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

public extension URLSession {
    final class WrappedTask {
        public var task: URLSessionDataTask?
    }

    enum DataError: LocalizedError {
        case unknown
        case custom(String)

        public var errorDescription: String? {
            switch self {
            case .unknown: return NSLocalizedString("Generic.unknownError", comment: "")
            case .custom(let message): return message
            }
        }
    }

    /// Downloads the contents of a URL based on the specified URL request and delivers the data asynchronously.
    /// - Parameter request: A URL request object that provides request-specific information such as the URL, cache policy, request type, and body data or body stream.
    /// - Returns: An asynchronously-delivered tuple that contains the URL contents as a `Data` instance, and a `URLResponse`.
    @available(iOS, deprecated: 15.0, message: "Use `URLSession.data(for:delegate:)` instead.")
    @available(macOS, deprecated: 12.0, message: "Use `URLSession.data(for:delegate:)` instead.")
    @available(tvOS, deprecated: 15.0, message: "Use `URLSession.data(for:delegate:)` instead.")
    @available(watchOS, deprecated: 8.0, message: "Use `URLSession.data(for:delegate:)` instead.")
    func legacyData(for request: URLRequest) async throws -> (Data, URLResponse) {
        let wrappedTask = WrappedTask()
        return try await withTaskCancellationHandler {
            wrappedTask.task?.cancel()
        } operation: {
            try await withUnsafeThrowingContinuation { continuation in
                wrappedTask.task = dataTask(with: request) { data, response, error in
                    if let error = error {
                        continuation.resume(with: .failure(error))
                    } else if let data = data, let response = response {
                        continuation.resume(with: .success((data, response)))
                    } else {
                        continuation.resume(with: .failure(DataError.unknown))
                    }
                }
                wrappedTask.task?.resume()
            }
        }
    }
}
