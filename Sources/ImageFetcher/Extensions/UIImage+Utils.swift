//
//  UIImage+Utils.swift
//  Mobelux
//
//  Created by Jeremy Greenwood on 2/22/18.
//  Copyright © 2018 Mobelux. All rights reserved.
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
