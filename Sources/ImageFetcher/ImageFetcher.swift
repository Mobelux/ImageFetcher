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
import DataOperation
import DiskCache

public final class ImageFetcher: ImageFetching {
    internal let cache: Cache
    internal let imageProcessor: ImageProcessing
    internal let networking: Networking
    private let lock = NSLock()
    private var tasks: [String: Task<ImageSource, Error>] = [:]

    public var taskCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return tasks.count
    }

    public init(
        _ cache: Cache,
        networking: Networking = .init(),
        imageProcessor: ImageProcessing
    ) {
        self.cache = cache
        self.networking = networking
        self.imageProcessor = imageProcessor
    }
}

// MARK: - Public API Methods
public extension ImageFetcher {
    /// Builds a `Task` to load an image for the given url.
    /// - Parameter url: The url of the image to be downloaded.
    /// - Returns: The parent task of the image loading operation.
    func task(_ url: URL) async -> Task<ImageSource, Error>  {
        await task(ImageConfiguration(url: url))
    }

    /// Builds a `Task` to download the given image configuration.
    /// - Parameter imageConfiguration: The configuation of the image to be downloaded.
    /// - Returns: The parent task of the image loading operation.
    func task(_ imageConfiguration: ImageConfiguration) async -> Task<ImageSource, Error> {
        if let existingTask = getTask(imageConfiguration) {
            return existingTask
        } else if let cachedData = try? await cache.data(imageConfiguration.key) {
            let decompressTask = Task(priority: imageConfiguration.priority) {
                try await decompress(cachedData, imageConfiguration: imageConfiguration)
            }

            insertTask(decompressTask, key: imageConfiguration)
            return decompressTask
        } else {
            let downloadTask = Task(priority: imageConfiguration.priority) {
                try await self.download(imageConfiguration)
            }

            insertTask(downloadTask, key: imageConfiguration)
            return downloadTask
        }
    }

    /// Loads the `URL`. If the result of the image configuration is cached, the result will be returned immediately. Otherwise a download operation will be kicked off.
    /// - Parameter url: The url of the image to be downloaded.
    /// - Returns: The loaded image.
    func load(_ url: URL) async throws -> ImageSource {
        try await load(ImageConfiguration(url: url))
    }

    /// Loads the `ImageConfiguration`. If the result of the image configuration is cached, the result will be returned immediately. Otherwise a download operation will be kicked off.
    /// - Parameter imageConfiguration: The configuation of the image to be downloaded.
    /// - Returns: The loaded image.
    func load(_ imageConfiguration: ImageConfiguration) async throws -> ImageSource {
        try await task(imageConfiguration).value
    }

    /// Cancels an in-flight image load.
    /// - Parameter url: The url of the image to be downloaded.
    func cancel(_ url: URL) {
        cancel(ImageConfiguration(url: url))
    }

    /// Cancels an in-flight image load.
    /// - Parameter imageConfiguration: The configuation of the image to be downloaded.
    func cancel(_ imageConfiguration: ImageConfiguration) {
        guard let task = removeTask(imageConfiguration) else {
            return
        }

        task.cancel()
    }

    /// Returns the `Task` associated with the given url, if one exists.
    /// - Parameter url: The url of the image to be downloaded.
    /// - Returns: The parent task of the image loading operation.
    subscript (_ url: URL) -> Task<ImageSource, Error>? {
        getTask(ImageConfiguration(url: url))
    }

    /// Returns the `Task` associated with the given configuration, if one exists
    /// - Parameter url: The configuration of the image to be downloaded.
    /// - Returns: The parent task of the image loading operation.
    subscript (_ imageConfiguration: ImageConfiguration) -> Task<ImageSource, Error>? {
        getTask(imageConfiguration)
    }

    /// Deletes all images in the cache.
    func deleteCache() async throws {
        try await cache.deleteAll()
    }

    /// Deletes image from the cache.
    /// - Parameter url: The url of the image to be deleted.
    func delete(_ url: URL) async throws {
        try await delete(ImageConfiguration(url: url))
    }

    /// Deletes image from the cache.
    /// - Parameter imageConfiguration: The configuation of the image to be deleted.
    func delete(_ imageConfiguration: ImageConfiguration) async throws {
        try await cache.delete(imageConfiguration.key)
    }

    /// Saves an image to the cache.
    /// - Parameters:
    ///   - image: The image instance.
    ///   - key: The url of the image to be saved.
    func cache(_ image: Image, key: URL) async throws {
        try await cache(image, key: ImageConfiguration(url: key))
    }

    /// Saves an image to the cache.
    /// - Parameters:
    ///   - image: The image instance.
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
        guard let cachedData = try? await cache.data(key.key) else {
            return nil
        }

        let decompressTask = Task(priority: key.priority) {
            try await decompress(cachedData, imageConfiguration: key)
        }

        insertTask(decompressTask, key: key)
        return try? await decompressTask.value.value
    }
}

// MARK: - Private Methods
private extension ImageFetcher {
    func download(_ imageConfiguration: ImageConfiguration) async throws -> ImageSource {
        do {
            let (data, _) = try await networking.load(URLRequest(url: imageConfiguration.url))
            let image = try await imageProcessor.process(data, configuration: imageConfiguration)
            removeTask(imageConfiguration)

            Task.detached(priority: .medium) { [weak self] in
                try? await self?.cache(image, key: imageConfiguration)
            }

            return .downloaded(image)
        } catch {
            removeTask(imageConfiguration)
            throw error
        }
    }

    func decompress(_ imageData: Data, imageConfiguration: ImageConfiguration) async throws -> ImageSource {
        do {
            let image = try await imageProcessor.decompress(imageData)
            removeTask(imageConfiguration)
            return .cached(image)
        } catch let error as CancellationError {
            removeTask(imageConfiguration)
            throw error
        } catch {
            return try await download(imageConfiguration)
        }
    }

    // MARK: Task Access

    func insertTask(_ imageFetcherTask: Task<ImageSource, Error>, key: ImageConfiguration) {
        lock.lock()
        defer { lock.unlock() }

        tasks[key.key] = imageFetcherTask
    }

    func getTask(_ key: ImageConfiguration) -> Task<ImageSource, Error>? {
        lock.lock()
        defer { lock.unlock() }

        return tasks[key.key]
    }

    @discardableResult
    func removeTask(_ key: ImageConfiguration) -> Task<ImageSource, Error>? {
        lock.lock()
        defer { lock.unlock() }

        return tasks.removeValue(forKey: key.key)
    }
}
