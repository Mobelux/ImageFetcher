//
//  ImageProcessorTests.swift
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
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

@testable import ImageFetcher
import Foundation
import XCTest

final class ImageProcessorTests: XCTestCase {
    let imageConfig = ImageConfiguration(url: Mock.makeURL())
    let imageData = Mock.makeImageData(side: 375)
}

// MARK: - Decompress
extension ImageProcessorTests {
    func testDecompress() async throws {
        let sut = ImageProcessor()
        let actualImage = try await sut.decompress(imageData)
        XCTAssertEqual(
            actualImage.pngData()!,
            Image(data: imageData)!.decompressed()!.pngData()!)
    }

    func testCancelDecompress() async throws {
        let sut = ImageProcessor()
        let task = Task {
            try await sut.decompress(imageData)
        }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Cancellation was not propagated.")
        } catch ImageError.cancelled {
            return
        } catch {
            XCTFail("Unexpected error")
        }
    }

    func testDecompressInvalidData() async throws {
        let invalidData = Data("Hello, world!".utf8)
        let sut = ImageProcessor()

        var caughtError: LocalizedError!
        let errorExpectation = expectation(description: "Error thrown")
        do {
            _ = try await sut.decompress(invalidData)
        } catch let error as LocalizedError  {
            caughtError = error
            errorExpectation.fulfill()
        } catch {
            XCTFail("Unexpected, non-localized error")
        }

        await fulfillment(of: [errorExpectation])
        XCTAssertEqual(
            caughtError.errorDescription,
            ImageError.cannotParse.errorDescription)
    }
}

// MARK: - Process
extension ImageProcessorTests {
    func testProcess() async throws {
        let initialSize = CGSize(width: 500, height: 500)
        let expectedSize = CGSize(width: 237, height: 237)
        let sourceImage = Color
            .random()
            .image(initialSize)

        let imageConfig = ImageConfiguration(
            url: Mock.makeURL(),
            size: expectedSize)

        let sut = ImageProcessor()
        _ = try await sut.process(sourceImage.pngData()!, configuration: imageConfig)
    }

    func testCancelProcess() async throws {
        let sut = ImageProcessor()
        let task = Task {
            try await sut.process(imageData, configuration: imageConfig)
        }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Cancellation was not propagated.")
        } catch ImageError.cancelled {
            return
        } catch {
            XCTFail("Unexpected error")
        }
    }

    func testProcessInvalidImage() async throws {
        let invalidData = Data("Hello, world!".utf8)
        let sut = ImageProcessor()

        var caughtError: LocalizedError!
        let errorExpectation = expectation(description: "Error thrown")
        do {
            _ = try await sut.process(invalidData, configuration: imageConfig)
        } catch let error as LocalizedError  {
            caughtError = error
            errorExpectation.fulfill()
        } catch {
            XCTFail("Unexpected, non-localized error")
        }

        await fulfillment(of: [errorExpectation])
        XCTAssertEqual(
            caughtError.errorDescription,
            ImageError.cannotParse.errorDescription)
    }
}
