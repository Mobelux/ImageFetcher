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
    func task(_ url: URL) async -> ImageFetcherTask
    func load(_ url: URL) async -> ImageResult
    func cancel(_ url: URL)
    func cache(_ image: Image, key: URL) async throws
    func delete(_ url: URL) async throws
    func deleteCache() async throws

    subscript (_ url: URL) -> ImageFetcherTask? { get }
}

public protocol ImageConfigurationFetching {
    func task(_ imageConfiguration: ImageConfiguration) async -> ImageFetcherTask
    func load(_ imageConfiguration: ImageConfiguration) async -> ImageResult
    func cancel(_ imageConfiguration: ImageConfiguration)
    func cache(_ image: Image, key: ImageConfiguration) async throws
    func delete(_ imageConfiguration: ImageConfiguration) async throws
    func deleteCache() async throws

    subscript (_ imageConfiguration: ImageConfiguration) -> ImageFetcherTask? { get }
}

public protocol ImageFetching: ImageURLFetching & ImageConfigurationFetching {}
