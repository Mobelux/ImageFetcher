//
//  MockImageProcessor.swift
//  Mobelux
//
//  MIT License
//
//  Copyright (c) 2023 Mobelux LLC
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import ImageFetcher

struct MockImageProcessor: ImageProcessing {
    var decompressDelay: TimeInterval? = nil
    var processDelay: TimeInterval? = nil
    var onDecompress: @Sendable (Data) async throws -> Image
    var onProcess: @Sendable (Data, ImageConfiguration) async throws -> Image
    var onCancellAll: @Sendable () -> Void

    init(
        decompressDelay: TimeInterval? = nil,
        processDelay: TimeInterval? = nil,
        onDecompress: @escaping @Sendable (Data) async throws -> Image = { Image(data: $0)! },
        onProcess: @escaping @Sendable (Data, ImageConfiguration) async throws -> Image = { data, _ in Image(data: data)! },
        onCancellAll: @escaping @Sendable () -> Void = {}
    ) {
        self.decompressDelay = decompressDelay
        self.processDelay = processDelay
        self.onDecompress = onDecompress
        self.onProcess = onProcess
        self.onCancellAll = onCancellAll
    }

    func decompress(_ data: Data) async throws -> Image {
        if let decompressDelay {
            try await Task.sleep(nanoseconds: UInt64(decompressDelay * 1_000_000_000))
            try Task.checkCancellation()
        }
        return try await onDecompress(data)
    }

    func process(_ data: Data, configuration: ImageConfiguration) async throws -> Image {
        if let processDelay {
            try await Task.sleep(nanoseconds: UInt64(processDelay * 1_000_000_000))
            try Task.checkCancellation()
        }
        return try await onProcess(data, configuration)
    }

    func cancelAll() {
        onCancellAll()
    }
}
