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
    func load(_ url: URL, handler: ImageHandler?)
    func cancel(_ url: URL)
    func cache(_ image: Image, key: URL) throws
    func delete(_ url: URL) throws
    func deleteCache() throws
}

public protocol ImageConfigurationFetching {
    func load(_ imageConfiguration: ImageConfiguration, handler: ImageHandler?)
    func cancel(_ imageConfiguration: ImageConfiguration)
    func cache(_ image: Image, key: ImageConfiguration) throws
    func delete(_ imageConfiguration: ImageConfiguration) throws
    func deleteCache() throws
}

public protocol ImageFetching: ImageURLFetching & ImageConfigurationFetching {}
