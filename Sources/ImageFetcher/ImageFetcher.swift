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

#if os(macOS)
import AppKit

extension NSImage {
    func pngData() -> Data? {
        guard let cgImage = cgImage else { return nil }

        return NSBitmapImageRep(cgImage: cgImage)
            .representation(using: .png, properties: [:])
    }
}
#else
import UIKit
#endif
import DiskCache

public actor ImageFetcher {
    internal var cache: Cache
    internal let networking: Networking

    private var tasks: [String: ImageFetcherTask] = [:]

    public init(_ cache: Cache, networking: Networking = .init()) {
        self.cache = cache
        self.networking = networking
    }
}

// MARK: - Public API Methods
public extension ImageFetcher {
    /*
    /// Builds a `ImageLoaderTask`. If the result of the image configuration is cached, `handler` will be called immediately. Otherwise a download operation will be kicked off
    /// - Parameters:
    ///   - url: The url of the image to be downloaded.
    ///   - handler: The handler which passes in an `ImageLoaderTask`. Always call on the main thread.
    func task(_ url: URL, handler: @escaping (ImageFetcherTask) -> ()) {
        task(ImageConfiguration(url: url), handler: handler)
    }

    /// Builds a `ImageLoaderTask`. If the result of the image configuration is cached, `handler` will be called immediately. Otherwise a download operation will be kicked off
    /// - Parameters:
    ///   - imageConfiguration: The configuation of the image to be downloaded.
    ///   - handler: The handler which passes in an `ImageLoaderTask`. Always call on the main thread.
    func task(_ imageConfiguration: ImageConfiguration, handler: @escaping (ImageFetcherTask) -> ()) {
        Task {
            let imageTask = await task(imageConfiguration)
            await MainActor.run {
                handler(imageTask)
            }
        }
    }

    /// Builds a `ImageLoaderTask`. If the result of the image configuration is cached, the task will be returned immediately. Otherwise a download operation will be kicked off.
    /// - Parameter url: The url of the image to be downloaded.
    /// - Returns: An instance of `ImageLoaderTask`. Be sure to check `result` before adding a handler.
    func task(_ url: URL) async -> ImageFetcherTask {
        await task(ImageConfiguration(url: url))
    }

    /// Builds a `ImageLoaderTask`. If the result of the image configuration is cached, the task will be returned immediately. Otherwise a download operation will be kicked off.
    /// - Parameter imageConfiguration: The configuation of the image to be downloaded.
    /// - Returns: An instance of `ImageLoaderTask`. Be sure to check `result` before adding a handler.
    func task(_ imageConfiguration: ImageConfiguration) async -> ImageFetcherTask {
        await withUnsafeContinuation { continuation in
            workerQueue.sync {
                // if data is cached, use it, else use `DataOperation` to fetch image data
                if let cachedData = try? cache.syncData(imageConfiguration.key),
                   let image = Image(data: cachedData)?.decompressed() {
                    continuation.resume(
                        returning: ImageFetcherTask(
                            configuration: imageConfiguration,
                            result: .success(.cached(image))))
                } else {
                    let operation = DataOperation(request: URLRequest(url: imageConfiguration.url))
                    operation.name = imageConfiguration.key

                    let task = ImageFetcherTask(configuration: imageConfiguration, operation: operation)
                    operation.completionBlock = completion(task: task)
                    queue.addOperation(operation)

                    continuation.resume(returning: task)
                }
            }
        }
    }

    /// Loads the `ImageConfiguration`. If the result of the image configuration is cached, `handler` will be called immediately. Otherwise a download operation will be kicked off.
    /// - Parameters:
    ///   - url: The url of the image to be downloaded.
    ///   - handler: The handler which passes in an `ImageHandler`. Always called on the main thread.
    func load(_ url: URL, handler: ImageHandler?) {
        load(ImageConfiguration(url: url), handler: handler)
    }

    /// Loads the `ImageConfiguration`. If the result of the image configuration is cached, `handler` will be called immediately. Otherwise a download operation will be kicked off.
    /// - Parameters:
    ///   - imageConfiguration: The configuation of the image to be downloaded.
    ///   - handler: The handler which passes in an `ImageHandler`. Always called on the main thread.
    func load(_ imageConfiguration: ImageConfiguration, handler: ImageHandler?) {
        Task {
            let imageResult = await load(imageConfiguration)
            await MainActor.run {
                handler?(imageResult)
            }
        }
    }
     */

    /// Loads the `ImageConfiguration`. If the result of the image configuration is cached, the result will be returned immediately. Otherwise a download operation will be kicked off.
    /// - Parameter url: The url of the image to be downloaded.
    /// - Returns: The result of the image load.
    func load(_ url: URL) async throws -> ResultType<Image> {
        try await load(ImageConfiguration(url: url))
    }

    /// Loads the `ImageConfiguration`. If the result of the image configuration is cached, the result will be returned immediately. Otherwise a download operation will be kicked off.
    /// - Parameter imageConfiguration: The configuation of the image to be downloaded.
    /// - Returns: The result of the image load.
    func load(_ imageConfiguration: ImageConfiguration) async throws -> ResultType<Image> {
        if let imageTask = tasks[imageConfiguration.key] {
            switch imageTask.state {
            case .pending(let task):
                let image = try await task.value
                return .downloaded(image)
            case .completed(let result):
                return result
            }
        }

        let task: Task<Image, Error> = Task(priority: imageConfiguration.priority) { [unowned self] in
            let request = URLRequest(url: imageConfiguration.url)
            let data = try await self.networking.load(request).0
            try Task.checkCancellation()

            guard let editedImage = Image(data: data)?.edit(configuration: imageConfiguration) else {
                throw ImageError.cannotParse
            }
            try Task.checkCancellation()

            try await cache(editedImage, key: imageConfiguration)
            return editedImage
        }

        tasks[imageConfiguration.key] = ImageFetcherTask(configuration: imageConfiguration, task: task)

        let image = try await task.value
        tasks[imageConfiguration.key] = ImageFetcherTask(configuration: imageConfiguration, result: .downloaded(image))
        return .downloaded(image)
    }

    /// Cancels an in-flight image load
    /// - Parameter url: The url of the image to be downloaded.
    func cancel(_ url: URL) {
        cancel(ImageConfiguration(url: url))
    }

    /// Cancels an in-flight image load
    /// - Parameter imageConfiguration: The configuation of the image to be downloaded.
    func cancel(_ imageConfiguration: ImageConfiguration) {
        guard let task = tasks[imageConfiguration.key], task.isPending else {
            return
        }
        task.cancel()
        tasks[imageConfiguration.key] = nil
    }

    subscript(_ url: URL) -> ImageFetcherTask? {
        self[ImageConfiguration(url: url)]
    }

    subscript(_ imageConfiguration: ImageConfiguration) -> ImageFetcherTask? {
        tasks[imageConfiguration.key]
    }

    /// Deletes all images in the cache
    func deleteCache() async throws {
        try await cache.deleteAll()
        tasks = [:]
    }

    /// Deletes image from the cache
    /// - Parameter imageConfiguration: The url of the image to be deleted.
    func delete(_ url: URL) throws {
        try delete(ImageConfiguration(url: url))
    }

    /// Deletes image from the cache
    /// - Parameter imageConfiguration: The configuation of the image to be deleted.
    func delete(_ imageConfiguration: ImageConfiguration) throws {
        try cache.syncDelete(imageConfiguration.key)
    }

    /// Saves in image to the cache
    /// - Parameters:
    ///   - image: The image instance
    ///   - key: The url of the image to be saved.
    func cache(_ image: Image, key: URL) async throws {
        try await cache(image, key: ImageConfiguration(url: key))
    }

    /// Saves in image to the cache
    /// - Parameters:
    ///   - image: The image instance
    ///   - key: The configuation of the image to be saved.
    func cache(_ image: Image, key: ImageConfiguration) async throws {
        guard let data = image.pngData() else {
            throw NSError(
                domain: "ImageFetcher.mobelux.com",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Could not convert image to PNG"])
        }

        try await cache.cache(data, key: key.key)
    }

    /// Loads an image from the cache.
    /// - Parameter key: The url of the image to load.
    /// - Returns:An image instance that has been previously cached. Nil if not found.
    func load(image key: URL) async -> Image? {
        await load(image: ImageConfiguration(url: key))
    }

    /// Loads an image from the cache.
    /// - Parameter key: The configuation of the image to load.
    /// - Returns:An image instance that has been previously cached. Nil if not found.
    func load(image key: ImageConfiguration) async -> Image? {
        guard let cachedData = try? await cache.data(key.key),
              let image = Image(data: cachedData)?.decompressed() else {
            return nil
        }
        return image
    }
}

