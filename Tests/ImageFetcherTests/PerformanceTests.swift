import XCTest
@testable import ImageFetcher

final class PerformanceTests: XCTestCase {
    enum Constants {
        static let baseURLString = "https://example.com"
        static let iterationCount = 500
        static let batchCount = 5
        static let requestCount = 10
        static let imageSide: Int = 250
        static let maxConcurrent: Int = 2
        static var imageSize: CGSize {
            .init(width: Self.imageSide, height: Self.imageSide)
        }
    }

    override class func tearDown() {
        super.tearDown()

        guard let searchPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first else {
            fatalError("\(#function) Fatal: Cannot get user directory.")
        }

        let directoryURL = searchPath.appendingPathComponent("com.mobelux.cache")
        do {
            try FileManager.default.removeItem(at: directoryURL)
        } catch {
            fatalError()
        }
    }

    override func tearDown() {
        super.tearDown()
        MockURLProtocol.reset()
    }

    static func makeURL(_ iteration: Int) -> URL {
        // Periodically hit the cache
        if iteration % 7 == 0 {
            return URL(string: Constants.baseURLString)!
        }

        return URL(string: "\(Constants.baseURLString)/\(iteration)")!
    }

    func testAsyncPerformance() async throws {
        MockURLProtocol.responseProvider = { url in
            (Color.random().image(Constants.imageSize).pngData()!, Mock.makeResponse(url: url))
        }

        measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            let cache = try! DiskCache(storageType: .temporary(.custom("\(Date().timeIntervalSince1970)")))
            let fetcher = ImageFetcher(cache, networking: Networking(.mock), imageProcessor: MockImageProcessor())

            let exp = expectation(description: "Finished")
            Task {
                try await withThrowingTaskGroup(of: ImageSource.self) { group in
                    for iteration in 0 ..< Constants.iterationCount {
                        group.addTask {
                            async let image = fetcher.load(Self.makeURL(iteration))
                            return try await image
                        }
                    }
                    try await group.waitForAll()
                }

                await MainActor.run {
                    stopMeasuring()
                }
                exp.fulfill()
            }

            wait(for: [exp], timeout: 20.0)
        }
    }

    func testAsyncPerformanceForBatches() async throws {
        MockURLProtocol.responseDelay = 0.3
        MockURLProtocol.responseProvider = { url in
            (Color.random().image(Constants.imageSize).pngData()!, Mock.makeResponse(url: url))
        }

        measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            let cache = try! DiskCache(storageType: .temporary(.custom("\(Date().timeIntervalSince1970)")))
            let fetcher = ImageFetcher(cache, networking: Networking(.mock), imageProcessor: MockImageProcessor())

            let exp = expectation(description: "Finished")
            Task {
                for iteration in 0 ..< Constants.batchCount {
                    try await withThrowingTaskGroup(of: ImageSource.self) { group in
                        for request in 0 ..< Constants.requestCount {
                            group.addTask {
                                async let image = fetcher.load(Self.makeURL(iteration * Constants.requestCount + request))
                                return try await image
                            }
                        }
                        try await group.waitForAll()
                    }
                    if iteration == Constants.batchCount - 1 {
                        await MainActor.run {
                            stopMeasuring()
                        }
                        exp.fulfill()
                    }
                }
            }

            wait(for: [exp], timeout: 20.0)
        }
    }
}
