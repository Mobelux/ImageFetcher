import Foundation
import ImageFetcher
import XCTest

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
}

final class MockURLProtocol: URLProtocol {
    static var responseQueue: DispatchQueue = .global()
    static var responseDelay: TimeInterval? = nil
    static var responseProvider: (URL) throws -> (Data, HTTPURLResponse) = { url in
        (Data(), Mock.makeResponse(url: url))
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let delay = Self.responseDelay {
            guard client != nil else { return }
            Self.responseQueue.asyncAfter(deadline: .now() + delay) {
                self.respond()
            }
        } else {
            respond()
        }
    }

    override func stopLoading() { }

    private func respond() {
        guard let client = client else { return }
        do {
            let url = try XCTUnwrap(request.url)
            let response = try Self.responseProvider(url)
            client.urlProtocol(self, didReceive: response.1, cacheStoragePolicy: .notAllowed)
            client.urlProtocol(self, didLoad: response.0)
        } catch {
            client.urlProtocol(self, didFailWithError: error)
        }
        client.urlProtocolDidFinishLoading(self)
    }
}

extension URLSessionConfiguration {
    static var mock: URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return config
    }
}

struct MockImageProcessor: ImageProcessing {
    var decompressDelay: TimeInterval? = nil
    var processDelay: TimeInterval? = nil
    var onDecompress: (Data) async throws -> Image
    var onProcess: (Data, ImageConfiguration) async throws -> Image

    init(
        decompressDelay: TimeInterval? = nil,
        processDelay: TimeInterval? = nil,
        onDecompress: @escaping (Data) async throws -> Image = { Image(data: $0)! },
        onProcess: @escaping (Data, ImageConfiguration) async throws -> Image = { data, _ in Image(data: data)! }
    ) {
        self.decompressDelay = decompressDelay
        self.processDelay = processDelay
        self.onDecompress = onDecompress
        self.onProcess = onProcess
    }

    func decompress(_ data: Data) async throws -> Image {
        if let decompressDelay {
            try await Task.sleep(nanoseconds: UInt64(decompressDelay * 1_000_000_000))
        }
        return try await onDecompress(data)
    }

    func process(_ data: Data, configuration: ImageConfiguration) async throws -> Image {
        if let processDelay {
            try await Task.sleep(nanoseconds: UInt64(processDelay * 1_000_000_000))
        }
        return try await onProcess(data, configuration)
    }
}
