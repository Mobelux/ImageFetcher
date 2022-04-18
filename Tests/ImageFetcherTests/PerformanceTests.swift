import XCTest
@testable import ImageFetcher

final class PerformanceTests: XCTestCase {
    enum Constants {
        static let iterationCount = 5_000
        static let imageSide: Int = 250
        static let baseURLString = "https://example.com"
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
        URLProtocolMock.responseProvider = { url in
            .success((Color.random().image(Constants.imageSize).pngData()!, Mock.makeResponse(url: url)))
        }

        measure {
            let fetcher = ImageFetcher(Self.cache, session: session)

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

    func testAsyncPerformance() async throws {
        let session = URLSession(configuration: .mock)
        URLProtocolMock.responseProvider = { url in
            .success((Color.random().image(Constants.imageSize).pngData()!, Mock.makeResponse(url: url)))
        }

        measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            let fetcher = ImageFetcher(Self.cache, session: session)

            let exp = expectation(description: "Finished")
            Task {
                await withThrowingTaskGroup(of: ImageResult.self) { group in
                    for iteration in 0 ..< Constants.iterationCount {
                        group.addTask {
                            async let image = fetcher.load(Self.makeURL(iteration))
                            return await image
                        }
                    }
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
}
