//
//  ImageLoading.swift
//  Customer
//
//  Created by Jeremy Greenwood on 3/23/18.
//  Copyright © 2018 Neighborhood Goods. All rights reserved.
//

import Foundation

public protocol ImageLoading {
    func task(_ imageConfiguration: ImageConfiguration, handler: @escaping (ImageLoaderTask) -> ())
    func load(_ imageConfiguration: ImageConfiguration, handler: ImageHandler?)
    func clear(_ imageConfiguration: ImageConfiguration)
    func delete(_ imageConfiguration: ImageConfiguration)

    subscript (_ imageConfiguration: ImageConfiguration) -> ImageLoaderTask? { get }
}
