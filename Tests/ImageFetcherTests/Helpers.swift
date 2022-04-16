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
        // Generate between 0 to 1
        let red = CGFloat(drand48())
        let green = CGFloat(drand48())
        let blue = CGFloat(drand48())

        return Color(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

enum Mock {
    static func makeResponse(url: URL, statusCode: Int = 200, headerFields: [String: String]? = nil) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headerFields)!
    }
}

final class URLProtocolMock: URLProtocol {
    static var responseProvider: (URL) -> Result<(Data, HTTPURLResponse), ImageError> = { url in
        .success((Data(), Mock.makeResponse(url: url)))
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let client = client else { return }

        do {
            let url = try XCTUnwrap(request.url)
            let result = Self.responseProvider(url)

            switch result {
            case let .success((data, response)):
                client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client.urlProtocol(self, didLoad: data)
            case .failure(let error):
                client.urlProtocol(self, didFailWithError: error)
            }
        } catch {
            client.urlProtocol(self, didFailWithError: error)
        }

        client.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }
}

extension URLSessionConfiguration {
    static var mock: URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        return config
    }
}
