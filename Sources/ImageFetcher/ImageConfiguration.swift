//
//  ImageConfiguration.swift
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

import Foundation
import CoreGraphics

extension TaskPriority: Hashable {}

/// The set of parameters the ``ImageLoader`` uses to download an image.
public struct ImageConfiguration: Hashable, Sendable {
    public let url: URL
    public let priority: TaskPriority?
    public let size: CGSize?
    public let constrain: Bool
    public let cornerRadius: Float
    public let scale: Float

    public init(
        url: URL,
        priority: TaskPriority? = nil,
        size: CGSize? = nil,
        constrain: Bool = false,
        cornerRadius: Float = 0.0,
        scale: Float = 1.0
    ) {
        self.url = url
        self.priority = priority
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
