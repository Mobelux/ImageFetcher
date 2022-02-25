//
//  ImageFetcher.swift
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
import DiskCache

public final class ImageFetcher: ImageFetching {
    private var queue: Queue
    private var cache: Cache
    private var tasks: Set<ImageFetcherTask> = []
    private var workerQueue = DispatchQueue.global()

    public init(_ cache: Cache, queue: Queue = OperationQueue(), maxConcurrent: Int = 2) {
        self.cache = cache
        self.queue = queue

        self.queue.maxConcurrentOperationCount = maxConcurrent
    }

    /// Builds a `ImageLoaderTask`. If the result of the image configuration is cached, `handler` will be called immediately. Otherwise a download operation will be kicked off
    /// - Parameters:
    ///   - imageConfiguration: The configuation of the image to be downloaded.
    ///   - handler: The handler which passes in an `ImageLoaderTask`
    public func task(_ imageConfiguration: ImageConfiguration, handler: @escaping (ImageFetcherTask) -> ()) {
        Task {
            let imageTask = await task(imageConfiguration)
            handler(imageTask)
        }
    }

    /// Builds a `ImageLoaderTask`. If the result of the image configuration is cached, the task will be returned immediately. Otherwise a download operation will be kicked off.
    /// - Parameter imageConfiguration: The configuation of the image to be downloaded.
    /// - Returns: An instance of `ImageLoaderTask`. Be sure to check `result` before adding a handler.
    public func task(_ imageConfiguration: ImageConfiguration) async -> ImageFetcherTask {
        await withCheckedContinuation { continuation in
            workerQueue.sync {
                // if data is cached, use it, else use `DataOperation` to fetch image data
                if let cachedData = try? self.cache.data(imageConfiguration.key),
                   let image = UIImage(data: cachedData)?.decompressed() {
                    continuation.resume(
                        returning: ImageFetcherTask(
                            configuration: imageConfiguration,
                            result: .success(.cached(image))))
                } else {
                    DispatchQueue.main.async {
                        let operation = DataOperation(request: URLRequest(url: imageConfiguration.url))
                        operation.name = imageConfiguration.key

                        let task = ImageFetcherTask(configuration: imageConfiguration, operation: operation)
                        operation.completionBlock = self.completion(task: task)
                        self.queue.addOperation(operation)

                        continuation.resume(returning: task)
                    }
                }
            }
        }
    }

    /// Loads the `ImageConfiguration`. If the result of the image configuration is cached, `handler` will be called immediately. Otherwise a download operation will be kicked off.
    /// - Parameters:
    ///   - imageConfiguration: The configuation of the image to be downloaded.
    ///   - handler: The handler which passes in an `ImageHandler`
    public func load(_ imageConfiguration: ImageConfiguration, handler: ImageHandler?) {
        Task {
            let imageResult = await load(imageConfiguration)
            handler?(imageResult)
        }
    }


    /// Loads the `ImageConfiguration`. If the result of the image configuration is cached, the result will be returned immediately. Otherwise a download operation will be kicked off.
    /// - Parameter imageConfiguration: The configuation of the image to be downloaded.
    /// - Returns: The result of the image load.
    public func load(_ imageConfiguration: ImageConfiguration) async -> ImageResult {
        let imageTask = await task(imageConfiguration)

        return await withCheckedContinuation { (continuation: CheckedContinuation<ImageResult, Never>) -> Void in
            workerQueue.sync {
                if let result = imageTask.result {
                    continuation.resume(returning: result)
                } else {
                    imageTask.handler = { result in
                        continuation.resume(returning: result)
                    }

                    tasks.insert(imageTask)
                }
            }
        }
    }

    public func cancel(_ imageConfiguration: ImageConfiguration) {
        guard let task = self[imageConfiguration] else {
            return
        }

        task.cancel()
        task.operation = nil
        task.handler = nil

        tasks.remove(task)
    }

    public subscript (_ imageConfiguration: ImageConfiguration) -> ImageFetcherTask? {
        return tasks.first(where: { (task) -> Bool in
            task.configuration == imageConfiguration
        })
    }
}

extension ImageFetcher {
    public func deleteCache() throws {
        try cache.deleteAll()
    }

    /*
     Deletes image configuration from the cache
     */
    public func delete(_ imageConfiguration: ImageConfiguration) throws {
        try cache.delete(imageConfiguration.key)
    }

    public func cache(_ image: UIImage, key: Keyable) throws {
        guard let data = image.pngData() else {
            throw NSError(domain: "ImageFetcher.mobelux.com", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to PNG"])
        }

        try self.cache.cache(data, key: key.key)
    }

    public func load(image key: Keyable) -> UIImage? {
        do {
            guard let cachedData = try? self.cache.data(key.key), let image = UIImage(data: cachedData) else {
                return nil
            }

            return image
        }
    }
}

private extension ImageFetcher {
    func completion(task: ImageFetcherTask) -> (() -> ()) {
        guard let operation = task.operation else {
            return {}
        }

        return { [weak operation, weak self] in
            guard let soperation = operation, let sself = self else {
                return
            }

            // grab the operation's result
            guard let result = soperation.result else {
                task.result = .failure(.noResult)
                return
            }

            // convert data result to image result
            let imageResult: ImageResult = {
                switch result {
                // data was successfully downloaded
                case .success(let data):
                    guard let image = UIImage(data: data), let editedImage = image.edit(configuration: task.configuration) else {
                        return .failure(.cannotParse)
                    }

                    do {
                        try sself.cache(editedImage, key: task.configuration)
                    } catch {
                        return .failure(ImageError.custom(error.localizedDescription))
                    }

                    return .success(.downloaded(editedImage))
                case .failure(let error):
                    return .failure(ImageError.convertFrom(error))
                }
            }()

            // call the handle with an image result
            task.result = imageResult
        }
    }
}

