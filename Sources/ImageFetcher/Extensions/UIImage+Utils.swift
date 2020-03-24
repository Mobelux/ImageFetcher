//
//  UIImage+Utils.swift
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

import UIKit

public extension UIImage {
    private func sizeFittingSize(_ maxSize: CGSize, size: CGSize) -> CGSize {
        let originalAspectRatio = size.width / size.height
        if size.width > size.height {
            let width = min(size.width, maxSize.width)
            return CGSize(width: width, height: ceil(width / originalAspectRatio))
        } else {
            let height = min(size.height, maxSize.height)
            return CGSize(width: ceil(height * originalAspectRatio), height: height)
        }
    }

    func rounded(_ radius: CGFloat, scale: CGFloat = 1.0) -> UIImage? {
        defer {
            UIGraphicsEndImageContext()
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        let rect = CGRect(origin: .zero, size: size)
        context.addPath(UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath)
        context.clip()

        draw(in: rect)

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    func resize(_ size: CGSize, constrain: Bool = false, cornerRadius: CGFloat = 0, scale: CGFloat = 1.0) -> UIImage? {
        if size.width.isNaN || size.height.isNaN {
            return nil
        }

        defer {
            UIGraphicsEndImageContext()
        }

        let finalSize = constrain ? sizeFittingSize(size, size: self.size) : size
        let rect = CGRect(origin: .zero, size: finalSize)

        UIGraphicsBeginImageContextWithOptions(finalSize, false, scale)

        if let context = UIGraphicsGetCurrentContext(), cornerRadius > 0 {
            context.addPath(UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).cgPath)
            context.clip()
        }

        draw(in: rect)

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    func edit(configuration: ImageConfiguration) -> UIImage? {
        guard configuration.size != nil || configuration.cornerRadius > 0 else {
            return self
        }

        return resize(configuration.size ?? size, constrain: configuration.constrain, cornerRadius: CGFloat(configuration.cornerRadius), scale: CGFloat(configuration.scale))
    }

    func decompressed() -> UIImage? {
        guard let imageRef = cgImage, let context = CGContext.init(data: nil,
                                     width: imageRef.width,
                                     height: imageRef.height,
                                     bitsPerComponent: 8,
                                     bytesPerRow: imageRef.width * 4,
                                     space: CGColorSpaceCreateDeviceRGB(),
                                     bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue) else { return nil }

        let rect = CGRect(origin: .zero, size: CGSize(width: imageRef.width, height: imageRef.height))
        context.draw(imageRef, in: rect)

        return context.makeImage().flatMap { UIImage(cgImage: $0, scale: scale, orientation: .up) }
    }
}
