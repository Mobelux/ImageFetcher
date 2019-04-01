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
public struct ImageConfiguration: Hashable {
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

extension ImageConfiguration: Keyable {
    public var key: String {
        let properties: [Any?] = [url, size, constrain, cornerRadius, scale]

        let keyValues = properties.compactMap {
            return $0 != nil ? String(describing: $0) : nil
        }

        return keyValues.joined().md5
    }
}
