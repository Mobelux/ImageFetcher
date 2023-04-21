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

#if os(macOS)
import AppKit

extension NSImage {
    var cgImage: CGImage? {
        var rect = CGRect.init(origin: .zero, size: size)
        return cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }

    func pngData() -> Data? {
        guard let cgImage = cgImage else { return nil }

        return NSBitmapImageRep(cgImage: cgImage)
            .representation(using: .png, properties: [:])
    }
}
#else
import UIKit
#endif

public extension Image {
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

    func decompressed(
        _ newSize: CGSize? = nil,
        constrain: Bool = false,
        cornerRadius: CGFloat = 0,
        scale: CGFloat = 1.0) -> Image? {
            let operatingSize = newSize ?? size
            let finalSize = constrain ? sizeFittingSize(operatingSize, size: size) : operatingSize

            guard let imageRef = cgImage,
                  let context = CGContext(
                    data: nil,
                    width: Int(finalSize.width),
                    height: Int(finalSize.height),
                    bitsPerComponent: 8,
                    bytesPerRow: Int(finalSize.width) * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
            else { return nil }

            let rect = CGRect(
                origin: .zero,
                size: finalSize
            )

            if cornerRadius > 0 {
                let path = CGPath(
                    roundedRect: rect,
                    cornerWidth: cornerRadius,
                    cornerHeight: cornerRadius,
                    transform: nil)

                context.addPath(path)
                context.clip()
            }

            context.draw(imageRef, in: rect)

            return context
                .makeImage()
                .flatMap {
                    #if os(macOS)
                    NSImage(
                        cgImage: $0,
                        size: rect.size)
                    #else
                    UIImage(
                        cgImage: $0,
                        scale: scale,
                        orientation: .up)
                    #endif
                }
        }

    func edit(configuration: ImageConfiguration) -> Image? {
        guard configuration.size != nil || configuration.cornerRadius > 0 else {
            return self
        }

        return decompressed(
            configuration.size ?? size,
            constrain: configuration.constrain,
            cornerRadius: CGFloat(configuration.cornerRadius),
            scale: CGFloat(configuration.scale))
    }
}
