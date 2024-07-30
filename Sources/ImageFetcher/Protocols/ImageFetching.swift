//
//  ImageFetching.swift
//  Customer
//
//  Created by Jeremy Greenwood on 3/23/18.
//  Copyright © 2018 Neighborhood Goods. All rights reserved.
//

import Foundation

/// A class of types that download and cache images from urls.
public protocol ImageURLFetching {
    /// Builds a `Task` to load an image for the given url.
    /// - Parameter url: The url of the image to be downloaded.
    /// - Returns: The parent task of the image loading operation.
    func task(_ url: URL) async -> Task<ImageSource, Error>

    /// Loads the `URL`. If the result of the image configuration is cached, the result will be returned immediately. Otherwise a download operation will be kicked off.
    /// - Parameter url: The url of the image to be downloaded.
    /// - Returns: The loaded image.
    func load(_ url: URL) async throws -> ImageSource

    /// Cancels an in-flight image load.
    /// - Parameter url: The url of the image to be downloaded.
    func cancel(_ url: URL)

    /// Saves an image to the cache.
    /// - Parameters:
    ///   - image: The image instance.
    ///   - key: The url of the image to be saved.
    func cache(_ image: Image, key: URL) async throws

    /// Deletes image from the cache.
    /// - Parameter url: The url of the image to be deleted.
    func delete(_ url: URL) async throws

    /// Deletes all images in the cache.
    func deleteCache() async throws

    /// Returns the `Task` associated with the given url, if one exists.
    /// - Parameter url: The url of the image to be downloaded.
    /// - Returns: The parent task of the image loading operation.
    subscript (_ url: URL) -> Task<ImageSource, Error>? { get }
}

/// A class of types that download and cache images from image configurations.
public protocol ImageConfigurationFetching {
    /// Builds a `Task` to download the given image configuration.
    /// - Parameter imageConfiguration: The configuation of the image to be downloaded.
    /// - Returns: The parent task of the image loading operation.
    func task(_ imageConfiguration: ImageConfiguration) async -> Task<ImageSource, Error>

    /// Loads the `ImageConfiguration`. If the result of the image configuration is cached, the result will be returned immediately. Otherwise a download operation will be kicked off.
    /// - Parameter imageConfiguration: The configuation of the image to be downloaded.
    /// - Returns: The loaded image.
    func load(_ imageConfiguration: ImageConfiguration) async throws -> ImageSource

    /// Cancels an in-flight image load.
    /// - Parameter imageConfiguration: The configuation of the image to be downloaded.
    func cancel(_ imageConfiguration: ImageConfiguration)

    /// Saves an image to the cache.
    /// - Parameters:
    ///   - image: The image instance.
    ///   - key: The configuation of the image to be saved.
    func cache(_ image: Image, key: ImageConfiguration) async throws

    /// Deletes image from the cache.
    /// - Parameter imageConfiguration: The configuation of the image to be deleted.
    func delete(_ imageConfiguration: ImageConfiguration) async throws

    /// Deletes all images in the cache.
    func deleteCache() async throws

    /// Returns the `Task` associated with the given configuration, if one exists
    /// - Parameter url: The configuration of the image to be downloaded.
    /// - Returns: The parent task of the image loading operation.
    subscript (_ imageConfiguration: ImageConfiguration) -> Task<ImageSource, Error>? { get }
}

/// A class of types that download and cache images.
public protocol ImageFetching: ImageURLFetching & ImageConfigurationFetching {}
