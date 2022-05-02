import XCTest
@testable import ImageFetcher

final class PerformanceTests: XCTestCase {
    enum Constants {
        static let baseURLString = "https://example.com"
        static let iterationCount = 1_000
        static let batchCount = 10
        static let requestCount = 10
        static let imageSide: Int = 250
        static let maxConcurrentTasks: Int = 2
        static var imageSize: CGSize {
            .init(width: Self.imageSide, height: Self.imageSide)
        }
    }

    static var cache: DiskCache!
    static let counter = Counter()

    override class func setUp() {
        super.setUp()
        do {
            cache = try DiskCache(storageType: .temporary(nil))
        } catch {
            XCTFail("Error: \(error)")
        }
    }

    override func tearDown() {
        print("\(#function)")
        super.tearDown()
        do {
            MockURLProtocol.responseDelay = nil
            try Self.cache.syncDeleteAll()
        } catch {
            print("Error: \(error)")
        }
    }

    static func makeURL(_ iteration: Int) -> URL {
        // Periodically hit the cache
        if iteration % 7 == 0 {
            return URL(string: Constants.baseURLString)!
        }

        return URL(string: "\(Constants.baseURLString)/\(iteration)")!
    }

    func testAsyncPerformanceWithoutMaxConcurrent() async throws {
        let networking = Networking(.mock)
        MockURLProtocol.responseProvider = { url in
            (Color.random().image(Constants.imageSize).pngData()!, Mock.makeResponse(url: url))
        }

        measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            let fetcher = ImageFetcher(Self.cache, networking: networking, maxConcurrentTasks: nil)

            let exp = expectation(description: "Finished")
            Task {
                let baseCount = await Self.counter.count * Constants.iterationCount
                try await withThrowingTaskGroup(of: ImageSource.self) { group in
                    for iteration in 0 ..< Constants.iterationCount {
                        group.addTask {
                            async let image = fetcher.load(Self.makeURL(iteration + baseCount))
                            return try await image
                        }
                    }
                    try await group.waitForAll()
                }

                await MainActor.run {
                    stopMeasuring()
                }
                await Self.counter.increment()
                exp.fulfill()
            }

            wait(for: [exp], timeout: 40.0)
        }

        await Self.counter.reset()
    }
    func testAsyncPerformanceWithMaxConcurrent() async throws {
        let networking = Networking(.mock)
        MockURLProtocol.responseProvider = { url in
            (Color.random().image(Constants.imageSize).pngData()!, Mock.makeResponse(url: url))
        }

        measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            let fetcher = ImageFetcher(Self.cache, networking: networking, maxConcurrentTasks: Constants.maxConcurrentTasks)

            let exp = expectation(description: "Finished")
            Task {
                let baseCount = await Self.counter.count * Constants.iterationCount
                try await withThrowingTaskGroup(of: ImageSource.self) { group in
                    for iteration in 0 ..< Constants.iterationCount {
                        group.addTask {
                            async let image = fetcher.load(Self.makeURL(iteration + baseCount))
                            return try await image
                        }
                    }
                    try await group.waitForAll()
                }

                await MainActor.run {
                    stopMeasuring()
                }
                await Self.counter.increment()
                exp.fulfill()
            }

            wait(for: [exp], timeout: 40.0)
        }

        await Self.counter.reset()
    }

    func testAsyncPerformanceForBatchesWithoutMaxConcurrent() async throws {
        let networking = Networking(.mock)
        MockURLProtocol.responseDelay = 0.3
        MockURLProtocol.responseProvider = { url in
            (Color.random().image(Constants.imageSize).pngData()!, Mock.makeResponse(url: url))
        }

        measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            let fetcher = ImageFetcher(Self.cache, networking: networking, maxConcurrentTasks: nil)

            let exp = expectation(description: "Finished")
            Task {
                let baseCount = await Self.counter.count * (Constants.requestCount * Constants.batchCount)

                for iteration in 0 ..< Constants.batchCount {
                    try await withThrowingTaskGroup(of: ImageSource.self) { group in
                        for request in 0 ..< Constants.requestCount {
                            group.addTask {
                                async let image = fetcher.load(Self.makeURL(iteration * Constants.requestCount + request + baseCount))
                                return try await image
                            }
                        }
                        try await group.waitForAll()
                    }
                    if iteration == Constants.batchCount - 1 {
                        await MainActor.run {
                            stopMeasuring()
                        }
                        await Self.counter.increment()
                        print("Done")
                        exp.fulfill()
                    }
                }
            }

            wait(for: [exp], timeout: 40.0)
        }

        await Self.counter.reset()
    }

    func testAsyncPerformanceForBatchesWithMaxConcurrent() async throws {
        let networking = Networking(.mock)
        MockURLProtocol.responseDelay = 0.3
        MockURLProtocol.responseProvider = { url in
            (Color.random().image(Constants.imageSize).pngData()!, Mock.makeResponse(url: url))
        }

        measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            let fetcher = ImageFetcher(Self.cache, networking: networking, maxConcurrentTasks: Constants.maxConcurrentTasks)

            let exp = expectation(description: "Finished")
            Task {
                let baseCount = await Self.counter.count * (Constants.requestCount * Constants.batchCount)

                for iteration in 0 ..< Constants.batchCount {
                    try await withThrowingTaskGroup(of: ImageSource.self) { group in
                        for request in 0 ..< Constants.requestCount {
                            group.addTask {
                                async let image = fetcher.load(Self.makeURL(iteration * Constants.requestCount + request + baseCount))
                                return try await image
                            }
                        }
                        try await group.waitForAll()
                    }
                    if iteration == Constants.batchCount - 1 {
                        await MainActor.run {
                            stopMeasuring()
                        }
                        await Self.counter.increment()
                        print("Done")
                        exp.fulfill()
                    }
                }
            }

            wait(for: [exp], timeout: 40.0)
        }

        await Self.counter.reset()
    }
}
