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

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public typealias ImageResult = Result<ImageSource, ImageError>
// TODO: remove
public typealias ImageHandler = (ImageResult) -> ()

public final class ImageFetcherTask {
    public enum State {
        case pending(Task<Image, Error>)
        case completed(ImageSource)
    }

    public var configuration: ImageConfiguration
    public private(set) var state: State
    public var isPending: Bool {
        if case .pending = state {
            return true
        } else {
            return false
        }
    }

    public convenience init(configuration: ImageConfiguration, task: Task<Image, Error>) {
        self.init(configuration: configuration, state: .pending(task))
    }

    public convenience init(configuration: ImageConfiguration, result: ImageSource) {
        self.init(configuration: configuration, state: .completed(result))
    }

    public init(configuration: ImageConfiguration, state: State) {
        self.configuration = configuration
        self.state = state
    }

    public func cancel() {
        guard case let .pending(task) = state else {
            return
        }
        task.cancel()
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
