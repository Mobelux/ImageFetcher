//
//  ImageFetching.swift
//  Customer
//
//  Created by Jeremy Greenwood on 3/23/18.
//  Copyright © 2018 Neighborhood Goods. All rights reserved.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public protocol ImageURLFetching {
    /// Builds a `ImageLoaderTask`. If the result of the image configuration is cached, `handler` will be called immediately. Otherwise a download operation will be kicked off
    /// - Parameters:
    ///   - url: The url of the image to be downloaded.
    ///   - handler: The handler which passes in an `ImageLoaderTask`. Always call on the main thread.
    func task(_ url: URL) async -> ImageFetcherTask

    /// Loads the `ImageConfiguration`. If the result of the image configuration is cached, `handler` will be called immediately. Otherwise a download operation will be kicked off.
    /// - Parameters:
    ///   - url: The url of the image to be downloaded.
    ///   - handler: The handler which passes in an `ImageHandler`. Always called on the main thread.
    func load(_ url: URL) async -> ImageResult

    /// Cancels an in-flight image load
    /// - Parameter url: The url of the image to be downloaded.
    func cancel(_ url: URL)

    /// Saves in image to the cache
    /// - Parameters:
    ///   - image: The image instance
    ///   - key: The url of the image to be saved.
    func cache(_ image: Image, key: URL) async throws

    /// Deletes image from the cache
    /// - Parameter url: The url of the image to be deleted.
    func delete(_ url: URL) async throws

    /// Deletes all images in the cache
    func deleteCache() async throws

    /// Returns the `ImageLoaderTask` associated with the given url, if one exists
    /// - Parameter url: The url of the image to be downloaded.
    /// - Returns: An instance of `ImageLoaderTask`. Be sure to check `result` before adding a handler.
    subscript (_ url: URL) -> ImageFetcherTask? { get }

    // Async support

    /// Builds a `ImageLoaderTask`. If the result of the image configuration is cached, the task will be returned immediately. Otherwise a download operation will be kicked off.
    /// - Parameter url: The url of the image to be downloaded.
    /// - Returns: An instance of `ImageLoaderTask`. Be sure to check `result` before adding a handler.
    func task(_ url: URL) async -> ImageFetcherTask

    /// Loads the `ImageConfiguration`. If the result of the image configuration is cached, the result will be returned immediately. Otherwise a download operation will be kicked off.
    /// - Parameter url: The url of the image to be downloaded.
    /// - Returns: The result of the image load.
    func load(_ url: URL) async -> ImageResult
}

public protocol ImageConfigurationFetching {
    /// Builds a `ImageLoaderTask`. If the result of the image configuration is cached, `handler` will be called immediately. Otherwise a download operation will be kicked off
    /// - Parameters:
    ///   - imageConfiguration: The configuation of the image to be downloaded.
    ///   - handler: The handler which passes in an `ImageLoaderTask`. Always call on the main thread.
    func task(_ imageConfiguration: ImageConfiguration) async -> ImageFetcherTask

    /// Loads the `ImageConfiguration`. If the result of the image configuration is cached, `handler` will be called immediately. Otherwise a download operation will be kicked off.
    /// - Parameters:
    ///   - imageConfiguration: The configuation of the image to be downloaded.
    ///   - handler: The handler which passes in an `ImageHandler`. Always called on the main thread.
    func load(_ imageConfiguration: ImageConfiguration) async -> ImageResult

    /// Cancels an in-flight image load
    /// - Parameter imageConfiguration: The configuation of the image to be downloaded.
    func cancel(_ imageConfiguration: ImageConfiguration)

    /// Saves in image to the cache
    /// - Parameters:
    ///   - image: The image instance
    ///   - key: The configuation of the image to be saved.
    func cache(_ image: Image, key: ImageConfiguration) async throws

    /// Deletes image from the cache
    /// - Parameter imageConfiguration: The configuation of the image to be deleted.
    func delete(_ imageConfiguration: ImageConfiguration) async throws

    /// Deletes all images in the cache
    func deleteCache() async throws

    /// Returns the `ImageLoaderTask` associated with the given configuration, if one exists
    /// - Parameter url: The configuration of the image to be downloaded.
    /// - Returns: An instance of `ImageLoaderTask`. Be sure to check `result` before adding a handler.
    subscript (_ imageConfiguration: ImageConfiguration) -> ImageFetcherTask? { get }

    // Async support

    /// Builds a `ImageLoaderTask`. If the result of the image configuration is cached, the task will be returned immediately. Otherwise a download operation will be kicked off.
    /// - Parameter imageConfiguration: The configuation of the image to be downloaded.
    /// - Returns: An instance of `ImageLoaderTask`. Be sure to check `result` before adding a handler.
    func task(_ imageConfiguration: ImageConfiguration) async -> ImageFetcherTask

    /// Loads the `ImageConfiguration`. If the result of the image configuration is cached, the result will be returned immediately. Otherwise a download operation will be kicked off.
    /// - Parameter imageConfiguration: The configuation of the image to be downloaded.
    /// - Returns: The result of the image load.
    func load(_ imageConfiguration: ImageConfiguration) async -> ImageResult
}

public protocol ImageFetching: ImageURLFetching & ImageConfigurationFetching {}
