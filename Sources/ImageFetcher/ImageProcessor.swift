//
//  ImageProcessor.swift
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

/// An object that decompresses and processes image data.
public final class ImageProcessor: ImageProcessing {
    private let queue: Queue

    /// Creates an image processor with the given queue and concurrent operation limit.
    ///
    /// If `maxConcurrent` is `nil`, the operation queue will instead use the recommended `OperationQueue.defaultMaxConcurrentOperationCount`
    /// value, causing the system to set the maximum number of operations dynamically based on current system conditions.
    ///
    /// - Parameters:
    ///   - queue: A queue that regulates the execution of operations.
    ///   - maxConcurrent: The maximum number of queued operations that can run at the same time.
    public init(
        queue: Queue = OperationQueue(),
        maxConcurrent: Int? = 2
    ) {
        self.queue = queue
        if let maxConcurrent {
            self.queue.maxConcurrentOperationCount = maxConcurrent
        }
    }

    /// Decompressed an image from the given data.
    /// - Parameter data: The image data.
    /// - Returns: The decompressed image.
    public func decompress(_ data: Data) async throws -> Image {
        let operation = ImageOperation(data: data, work: .decompress)

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                operation.completionBlock = { [weak operation] in
                    guard let result = operation?.result else {
                        continuation.resume(throwing: ImageError.noResult)
                        return
                    }

                    continuation.resume(with: result)
                }

                queue.addOperation(operation)
            }
        } onCancel: {
            operation.cancel()
        }
    }

    /// Processes an image from the given data and configuration.
    /// - Parameters:
    ///   - data: The image data.
    ///   - configuration: The configuation of the image to by processed.
    /// - Returns: The processed image.
    public func process(_ data: Data, configuration: ImageConfiguration) async throws -> Image {
        let operation = ImageOperation(data: data, work: .edit(configuration))

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                operation.completionBlock = { [weak operation] in
                    guard let result = operation?.result else {
                        continuation.resume(throwing: ImageError.noResult)
                        return
                    }

                    continuation.resume(with: result)
                }

                queue.addOperation(operation)
            }
        } onCancel: {
            operation.cancel()
        }
    }

    /// Cancels all queued and executing operations.
    public func cancelAll() {
        queue.cancelAllOperations()
    }
}

// MARK: - Supporting

extension Operation {
    static let isFinishedKey = "isFinished"
    static let isExecutingKey = "isExecuting"
}

final class ImageOperation: Operation, @unchecked Sendable {
    enum Work: Equatable {
        case decompress
        case edit(ImageConfiguration)
    }

    let data: Data
    let work: Work
    private(set) var result: Result<Image, ImageError>?

    init(data: Data, work: Work) {
        self.data = data
        self.work = work
    }

    override func start() {
        guard !isCancelled else {
            return update(.failure(.cancelled))
        }

        guard let image = Image(data: data) else {
            return update(.failure(.cannotParse))
        }

        switch work {
        case .decompress:
            guard let decompressed = image.decompressed() else {
                return update(.failure(.cannotParse))
            }

            update(.success(decompressed))
        case .edit(let configuration):
            guard let editedImage = image.edit(configuration: configuration) else {
                return update(.failure(.cannotParse))
            }

            update(.success(editedImage))
        }
    }

    override var isExecuting: Bool {
        result == nil
    }

    override var isFinished: Bool {
        result != nil
    }

    override var isAsynchronous: Bool {
        true
    }
}

private extension ImageOperation {
    func update(_ result: Result<Image, ImageError>?) {
        self.willChangeValue(forKey: Operation.isFinishedKey)
        self.willChangeValue(forKey: Operation.isExecutingKey)

        self.result = result

        self.didChangeValue(forKey: Operation.isExecutingKey)
        self.didChangeValue(forKey: Operation.isFinishedKey)
    }
}
