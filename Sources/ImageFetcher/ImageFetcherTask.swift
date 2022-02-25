//
//  ImageFetcherTask.swift
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

import UIKit
import DataOperation

public typealias ImageResult = Result<ResultType<UIImage>, ImageError>
public typealias ImageHandler = (ImageResult) -> ()

public final class ImageFetcherTask {
    var operation: DataOperation?

    public var handler: ImageHandler?
    public var configuration: ImageConfiguration
    public var result: ImageResult? {
        didSet {
            guard let result = result else {
                return
            }

            handler?(result)
            operation = nil
        }
    }

    public init(configuration: ImageConfiguration, operation: DataOperation? = nil, result: ImageResult? = nil) {
        self.configuration = configuration
        self.operation = operation
        self.result = result
    }

    public func cancel() {
        operation?.cancel()
        operation = nil
    }
}

extension ImageFetcherTask: Equatable {
    static public func == (lhs: ImageFetcherTask, rhs: ImageFetcherTask) -> Bool {
        return lhs.configuration == rhs.configuration
    }
}

extension ImageFetcherTask: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuration)
    }
}
