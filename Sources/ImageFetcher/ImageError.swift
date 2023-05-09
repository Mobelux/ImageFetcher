//
//  ImageError.swift
//  Mobelux
//
//  MIT License
//
//  Copyright (c) 2020 Mobelux LLC
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

/// An error that occurs while fetching an image.
public enum ImageError: LocalizedError {
    /// An indication that an image fetching task was cancelled.
    case cancelled
    /// An indication that the image data could not be parsed.
    case cannotParse
    /// An indication that an operation lacked a result.
    case noResult
    /// An indication that an unknown error occurred.
    case unknown
    /// An indication that an error with a custom message occurred.
    case custom(String)

    /// A Boolean value indicating whether an error was the result of a cancelled task.
    public var wasCancelled: Bool {
        switch self {
        case .cancelled: return true
        default: return false
        }
    }

    /// A localized message describing what error occurred.
    public var errorDescription: String {
        switch self {
        case .cancelled: return NSLocalizedString("ImageLoader.cancelled", comment: "")
        case .cannotParse: return NSLocalizedString("ImageLoader.cannotParse", comment: "")
        case .noResult: return NSLocalizedString("ImageLoader.noResult", comment: "")
        case .unknown: return NSLocalizedString("Generic.unknownError", comment: "")
        case .custom(let message): return message
        }
    }
}
