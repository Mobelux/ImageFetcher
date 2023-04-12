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
}
