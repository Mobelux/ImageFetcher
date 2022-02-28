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

public protocol ImageFetching {
    func task(_ imageConfiguration: ImageConfiguration, handler: @escaping (ImageFetcherTask) -> ())
    func load(_ imageConfiguration: ImageConfiguration, handler: ImageHandler?)
    func clear(_ imageConfiguration: ImageConfiguration)
    func cache(_ image: Image, key: ImageConfiguration) throws
    func delete(_ imageConfiguration: ImageConfiguration) throws
    func deleteCache() throws

    subscript (_ imageConfiguration: ImageConfiguration) -> ImageFetcherTask? { get }
}
