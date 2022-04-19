import XCTest
@testable import ImageFetcher

final class PerformanceTests: XCTestCase {
    enum Constants {
        static let baseURLString = "https://example.com"
        static let iterationCount = 1_000
        static let batchCount = 10
        static let requestCount = 10
        static let imageSide: Int = 250
        static let maxConcurrent: Int = 2
        static var imageSize: CGSize {
            .init(width: Self.imageSide, height: Self.imageSide)
        }
    }

    static var cache: DiskCache!

    override class func setUp() {
        super.setUp()
        do {
            cache = try DiskCache(storageType: .temporary(nil))
        } catch {
            fatalError()
        }
    }

    override func tearDown() {
        super.tearDown()
        do {
            MockURLProtocol.responseDelay = nil
            try Self.cache.syncDeleteAll()
        } catch {
            fatalError()
        }
    }

    static func makeURL(_ iteration: Int) -> URL {
        // Periodically hit the cache
        if iteration % 7 == 0 {
            return URL(string: Constants.baseURLString)!
        }

        return URL(string: "\(Constants.baseURLString)/\(iteration)")!
    }

    func testSyncPerformance() throws {
        let session = URLSession(configuration: .mock)
        MockURLProtocol.responseProvider = { url in
            (Color.random().image(Constants.imageSize).pngData()!, Mock.makeResponse(url: url))
        }

        measure {
            let fetcher = ImageFetcher(Self.cache, session: session, maxConcurrent: Constants.maxConcurrent)

            var responseCount = 0
            let exp = expectation(description: "Finished")
            for iteration in 0 ..< Constants.iterationCount {
                fetcher.load(Self.makeURL(iteration)) { _ in
                    responseCount += 1

                    if responseCount == Constants.iterationCount {
                        exp.fulfill()
                    }
                }
            }

            wait(for: [exp], timeout: 20.0)
            do {
                try Self.cache.syncDeleteAll()
            } catch {
                XCTFail()
            }
            print("Done")
        }
    }

    func testSyncPerformanceWithBatches() throws {
        let session = URLSession(configuration: .mock)
        MockURLProtocol.responseDelay = 0.3
        MockURLProtocol.responseProvider = { url in
            (Color.random().image(Constants.imageSize).pngData()!, Mock.makeResponse(url: url))
        }

        measure {
            let fetcher = ImageFetcher(Self.cache, session: session, maxConcurrent: Constants.maxConcurrent)

            let exp = expectation(description: "Finished")
            for iteration in 0 ... Constants.batchCount {
                var responseCount = 0
                let innerExp = expectation(description: "Finished Iteration Requests")
                for request in 0 ..< Constants.requestCount {
                    fetcher.load(Self.makeURL(iteration * Constants.requestCount + request)) { _ in
                        responseCount += 1
                        if responseCount == Constants.requestCount {
                            innerExp.fulfill()
                        }
                    }
                }

                wait(for: [innerExp], timeout: 5.0)
                if iteration == Constants.batchCount {
                    exp.fulfill()
                }
            }

            wait(for: [exp], timeout: 15.0)
            do {
                try Self.cache.syncDeleteAll()
            } catch {
                XCTFail()
            }
            print("Done")
        }
    }

    func testAsyncPerformance() async throws {
        let session = URLSession(configuration: .mock)
        MockURLProtocol.responseProvider = { url in
            (Color.random().image(Constants.imageSize).pngData()!, Mock.makeResponse(url: url))
        }

        measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            let fetcher = ImageFetcher(Self.cache, session: session, maxConcurrent: Constants.maxConcurrent)

            let exp = expectation(description: "Finished")
            Task {
                try await withThrowingTaskGroup(of: ImageResult.self) { group in
                    for iteration in 0 ..< Constants.iterationCount {
                        group.addTask {
                            async let image = fetcher.load(Self.makeURL(iteration))
                            return await image
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
            do {
                try Self.cache.syncDeleteAll()
            } catch {
                XCTFail()
            }
            print("Done")
        }
    }

    func testAsyncPerformanceForBatches() async throws {
        let session = URLSession(configuration: .mock)
        MockURLProtocol.responseDelay = 0.3
        MockURLProtocol.responseProvider = { url in
            (Color.random().image(Constants.imageSize).pngData()!, Mock.makeResponse(url: url))
        }

        measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            let fetcher = ImageFetcher(Self.cache, session: session, maxConcurrent: Constants.maxConcurrent)

            let exp = expectation(description: "Finished")
            Task {
                for iteration in 0 ..< Constants.batchCount {
                    try await withThrowingTaskGroup(of: ImageResult.self) { group in
                        for request in 0 ..< Constants.requestCount {
                            group.addTask {
                                async let image = fetcher.load(Self.makeURL(iteration * Constants.requestCount + request))
                                return await image
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
            do {
                try Self.cache.syncDeleteAll()
            } catch {
                XCTFail()
            }
            print("Done")
        }
    }
}
