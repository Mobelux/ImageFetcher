import XCTest
@testable import ImageFetcher

final class ImageFetcherTests: XCTestCase {
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

    func testCompletedTaskRemoval() throws {
        let session = URLSession(configuration: .mock)
        MockURLProtocol.responseProvider = { url in
            (Data(), Mock.makeResponse(url: url))
        }
        let fetcher = ImageFetcher(Self.cache, session: session)

        let exp = expectation(description: "Finished")
        fetcher.load(Mock.baseURL) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)

        let expected = 0
        let actual = fetcher.taskCount
        XCTAssertEqual(expected, actual)
    }

    func testSubscriptAccess() async throws {
        let requestCount: Int = 100

        // Config
        let session = URLSession(configuration: .mock)
        MockURLProtocol.responseDelay = 0.1
        MockURLProtocol.responseProvider = { url in
            (Color.random().image(CGSize(width: 100, height: 100)).pngData()!, Mock.makeResponse(url: url))
        }

        let sut = ImageFetcher(Self.cache, session: session, maxConcurrent: 4)

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
