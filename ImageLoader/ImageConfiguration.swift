//
//  ImageConfiguration.swift
//  Mobelux
//
//  Created by Jeremy Greenwood on 2/21/18.
//  Copyright © 2018 Mobelux. All rights reserved.
//

import Foundation
import QuartzCore

/*
 The set of parameters the `ImageLoader` uses to download an image.
 */
public struct ImageConfiguration {
    public let url: URL
    public let size: CGSize?
    public let constrain: Bool
    public let cornerRadius: Float
    public let scale: Float

    public init(url: URL, size: CGSize? = nil, constrain: Bool = false, cornerRadius: Float = 0.0, scale: Float = 1.0) {
        self.url = url
        self.size = size
        self.constrain = constrain
        self.cornerRadius = cornerRadius
        self.scale = scale
    }
}

extension ImageConfiguration: Equatable {
    static public func == (lhs: ImageConfiguration, rhs: ImageConfiguration) -> Bool {
        return lhs.url == rhs.url &&
        lhs.size == rhs.size &&
        lhs.constrain == rhs.constrain &&
        lhs.cornerRadius == rhs.cornerRadius &&
        lhs.scale == rhs.scale
    }
}

extension ImageConfiguration: Keyable {
    public var key: String {
        let properties: [Any?] = [url, size, constrain, cornerRadius, scale]

        let keyValues = properties.flatMap {
            return $0 != nil ? String(describing: $0) : nil
        }

        return String(keyValues.joined().hashValue)
    }
}