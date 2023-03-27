//
//  ImageProcessor.swift
//  Mobelux
//
//  MIT License
//
//  Copyright (c) 2023 Mobelux LLC
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

public final class ImageProcessor: ImageProcessing {
    /// Decompressed an image from the given data.
    /// - Parameter data: The image data.
    /// - Returns: The decompressed image.
    public func decompress(_ data: Data) async throws -> Image {
        guard let image = Image(data: data)?.decompressed() else {
            throw ImageError.cannotParse
        }

        return image
    }

    /// Processes an image from the given data and configuration.
    /// - Parameters:
    ///   - data: The image data.
    ///   - configuration: The configuation of the image to by processed..
    /// - Returns: The processed image.
    public func process(_ data: Data, configuration: ImageConfiguration) async throws -> Image {
        guard let image = Image(data: data), let editedImage = image.edit(configuration: configuration) else {
            throw ImageError.cannotParse
        }

        return editedImage
    }
}