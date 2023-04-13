import XCTest
@testable import ImageFetcher

final class ImageFetcherTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        MockURLProtocol.reset()
    }

    func testCompletedTaskRemoval() async throws {
        MockURLProtocol.responseProvider = { url in
            (Mock.makeImageData(side: 150), Mock.makeResponse(url: url))
        }
        let cache = MockCache(onData: { _ in throw MockCache.CacheError(reason: "File missing") })
        let fetcher = ImageFetcher(cache, networking: Networking(.mock), imageProcessor: MockImageProcessor())

        let exp = expectation(description: "Finished")
        _ = try await fetcher.load(Mock.baseURL)
        exp.fulfill()

        await fulfillment(of: [exp], timeout: 1.0)

        let expected = 0
        let actual = fetcher.taskCount
        XCTAssertEqual(expected, actual)
    }

    func testContinuationsAreNotLeaked() async throws {
        let session = URLSession(configuration: .mock)
        MockURLProtocol.responseDelay = 5.0
        MockURLProtocol.responseProvider = { url in
            (Color.random().image(CGSize(width: 100, height: 100)).pngData()!, Mock.makeResponse(url: url))
        }

        let cache = MockCache(onData: { _ in throw MockCache.CacheError(reason: "File missing") })
        let sut = ImageFetcher(cache, session: session)

        let url = URL(string: "https://example.com")!
        async let result = await sut.load(url)

        try await Task.sleep(nanoseconds: NSEC_PER_SEC)
        sut.cancel(url)

        let awaitedResult = await result
        switch awaitedResult {
        case .failure(.noResult):
            return
        default:
            XCTFail("Result \(awaitedResult) was not a cancellation error")
        }
    }

    func testSubscriptAccess() async throws {
        let requestCount: Int = 100

        // Config
        let session = URLSession(configuration: .mock)
        MockURLProtocol.responseDelay = 0.1
        MockURLProtocol.responseProvider = { url in
            (Color.random().image(CGSize(width: 100, height: 100)).pngData()!, Mock.makeResponse(url: url))
        }

        let cache = MockCache(onData: { _ in throw MockCache.CacheError(reason: "File missing") })
        let sut = ImageFetcher(cache, networking: Networking(.mock), imageProcessor: MockImageProcessor())

        async let images = await withThrowingTaskGroup(of: Image.self, returning: [Image].self) { taskGroup in
            for iteration in 0 ..< requestCount {
                let url = Mock.makeURL(iteration)

                taskGroup.addTask {
                    try await sut.load(url).get().value
                }
            }

            return try await taskGroup.reduce(into: [Image]()) { images, image in
                    images.append(image)
            }
        }

        async let subscriptAccess: Void = await withTaskGroup(of: Void.self) { taskGroup in
            for iteration in 0 ..< 1_000_000 {
                let url = Mock.makeURL(iteration)

                taskGroup.addTask {
                    _ = sut[url]
                }
            }
        }

        _ = try await (images, subscriptAccess)
    }
}
