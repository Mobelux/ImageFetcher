import Foundation
import XCTest
@testable import ImageFetcher

#if os(macOS)
import AppKit

public typealias Color = NSColor

extension Color {
    public func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> Image {
        let image = Image(size: size)
        image.lockFocus()
        drawSwatch(in: NSRect(origin: .zero, size: size))
        image.unlockFocus()
        return image
    }
}
#else
import UIKit

public typealias Color = UIColor

extension Color {
    public func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}
#endif

extension Color {
    public static func random() -> Color {
        .init(
            red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: 1.0)
    }
}

enum Mock {
    static var baseURL = URL(string: "https://example.com")!

    static func makeImageData(side: CGFloat) -> Data {
        Color
            .random()
            .image(CGSize(width: side, height: side))
            .pngData()!
    }

    static func makeResponse(url: URL, statusCode: Int = 200, headerFields: [String: String]? = nil) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headerFields)!
    }

    static func makeURL(_ iteration: Int, hitCache: (Int) -> Bool = { $0 % 7 == 0 }) -> URL {
        // Periodically hit the cache
        if hitCache(iteration) {
            return baseURL
        }

        return baseURL.appendingPathComponent("\(iteration)")
    }
}

extension Networking {
    static func mock(
        responseDelay: TimeInterval? = nil,
        responseProvider: @escaping (URL) throws -> (Data, HTTPURLResponse) = { (Data(), Mock.makeResponse(url: $0)) }
    ) -> Self {
        .init(
            load: { request in
                if let responseDelay {
                    try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
                    try Task.checkCancellation()
                }
                return try responseProvider(request.url!)
            })
    }
}

class MockCache: Cache {
    struct CacheError: Error {
        let reason: String
    }

    var onCache: (Data, String) throws -> ()
    var onData: (String) throws -> Data
    var onDelete: (String) throws -> ()
    var onDeleteAll: () throws -> ()
    var onFileURL: (String) -> URL

    init(
        onCache: @escaping (Data, String) throws -> () = { _, _ in },
        onData: @escaping (String) throws -> Data = { _ in Data() },
        onDelete: @escaping (String) throws -> () = { _ in },
        onDeleteAll: @escaping () throws -> () = { },
        onFileURL: @escaping (String) -> URL = { _ in URL(fileURLWithPath: "") }
    ) {
        self.onCache = onCache
        self.onData = onData
        self.onDelete = onDelete
        self.onDeleteAll = onDeleteAll
        self.onFileURL = onFileURL
    }

    func syncCache(_ data: Data, key: String) throws {
        try onCache(data, key)
    }

    func syncData(_ key: String) throws -> Data {
        try onData(key)
    }

    func syncDelete(_ key: String) throws {
        try onDelete(key)
    }

    func syncDeleteAll() throws {
        try onDeleteAll()
    }

    func fileURL(_ key: String) -> URL {
        onFileURL(key)
    }

    // Async support

    func cache(_ data: Data, key: String) async throws {
        try onCache(data, key)
    }

    func data(_ key: String) async throws -> Data {
        try onData(key)
    }

    func delete(_ key: String) async throws {
        try onDelete(key)
    }

    func deleteAll() async throws {
        try onDeleteAll()
    }
}

struct MockImageProcessor: ImageProcessing {
    var decompressDelay: TimeInterval? = nil
    var processDelay: TimeInterval? = nil
    var onDecompress: (Data) async throws -> Image
    var onProcess: (Data, ImageConfiguration) async throws -> Image
    var onCancellAll: () -> Void

    init(
        decompressDelay: TimeInterval? = nil,
        processDelay: TimeInterval? = nil,
        onDecompress: @escaping (Data) async throws -> Image = { Image(data: $0)! },
        onProcess: @escaping (Data, ImageConfiguration) async throws -> Image = { data, _ in Image(data: data)! },
        onCancellAll: @escaping () -> Void = {}
    ) {
        self.decompressDelay = decompressDelay
        self.processDelay = processDelay
        self.onDecompress = onDecompress
        self.onProcess = onProcess
        self.onCancellAll = onCancellAll
    }

    func decompress(_ data: Data) async throws -> Image {
        if let decompressDelay {
            try await Task.sleep(nanoseconds: UInt64(decompressDelay * 1_000_000_000))
            try Task.checkCancellation()
        }
        return try await onDecompress(data)
    }

    func process(_ data: Data, configuration: ImageConfiguration) async throws -> Image {
        if let processDelay {
            try await Task.sleep(nanoseconds: UInt64(processDelay * 1_000_000_000))
            try Task.checkCancellation()
        }
        return try await onProcess(data, configuration)
    }

    func cancelAll() {
        onCancellAll()
    }
}

#if swift(<5.8)
extension XCTestCase {
    /// Waits on a group of expectations for up to the specified timeout, optionally enforcing their order of fulfillment.
    ///
    /// This allows use of Xcode 14.3's `XCTestCase.fulfillment(of:timeout:enforceOrder:)` method while maintaining
    /// compatibility with previous versions.
    ///
    /// - Parameters:
    ///   - expectations: An array of expectations the test must satisfy.
    ///   - seconds: The time, in seconds, the test allows for the fulfillment of the expectations. The default timeout
    ///   allows the test to run until it reaches its execution time allowance.
    ///   - enforceOrderOfFulfillment: If `true`, the test must satisfy the expectations in the order they appear in
    ///   the array.
    func fulfillment(
        of expectations: [XCTestExpectation],
        timeout seconds: TimeInterval = .infinity,
        enforceOrder enforceOrderOfFulfillment: Bool = false
    ) async {
        await MainActor.run {
            wait(for: expectations, timeout: seconds, enforceOrder: enforceOrderOfFulfillment)
        }
    }
}
#endif
