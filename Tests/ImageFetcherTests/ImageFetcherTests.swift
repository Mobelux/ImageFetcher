import XCTest
@testable import ImageFetcher

final class ImageFetcherTests: XCTestCase {
    func testCompletedTaskRemoval() async throws {
        let cache = MockCache(onData: { _ in throw MockCache.CacheError(reason: "File missing") })
        let networking = Networking.mock(delay: 0.1) { (Mock.makeImageData(side: 150), Mock.makeResponse(url: $0)) }
        let fetcher = ImageFetcher(cache, networking: networking, imageProcessor: MockImageProcessor())

        let exp = expectation(description: "Finished")
        _ = try await fetcher.load(Mock.baseURL)
        exp.fulfill()

        await fulfillment(of: [exp], timeout: 1.0)

        let expected = 0
        let actual = fetcher.taskCount
        XCTAssertEqual(expected, actual)
    }

    func testContinuationsAreNotLeaked() async throws {
        let cache = MockCache(onData: { _ in throw MockCache.CacheError(reason: "File missing") })
        let networking = Networking.mock(delay: 1.0) { (Mock.makeImageData(side: 150), Mock.makeResponse(url: $0)) }
        let sut = ImageFetcher(cache, networking: networking, imageProcessor: MockImageProcessor())

        let url = URL(string: "https://example.com")!

        let exp = expectation(description: "Request threw error")
        Task {
            do {
                let result = try await sut.load(url)
            } catch {
                XCTAssert(error is CancellationError)
                exp.fulfill()
            }
        }

        try await Task.sleep(nanoseconds: 500_000)
        sut.cancel(url)

        await fulfillment(of: [exp], timeout: 1.0)
    }

    func testSubscriptAccess() async throws {
        let requestCount: Int = 100

        let cache = MockCache(onData: { _ in throw MockCache.CacheError(reason: "File missing") })
        let networking = Networking.mock(delay: 0.1) { url in
            (Color.random().image(CGSize(width: 100, height: 100)).pngData()!, Mock.makeResponse(url: url))
        }
        let sut = ImageFetcher(cache, networking: networking, imageProcessor: MockImageProcessor())

        async let images = await withThrowingTaskGroup(of: Image.self, returning: [Image].self) { taskGroup in
            for iteration in 0 ..< requestCount {
                let url = Mock.makeURL(iteration)

                taskGroup.addTask {
                    try await sut.load(url).value
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
