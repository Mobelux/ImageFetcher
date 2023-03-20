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

    func testCompletedTaskRemoval() async throws {
        let session = URLSession(configuration: .mock)
        MockURLProtocol.responseProvider = { url in
            (Data(), Mock.makeResponse(url: url))
        }
        let fetcher = ImageFetcher(Self.cache, session: session)

        let exp = expectation(description: "Finished")
        _ = await fetcher.load(Mock.baseURL)
        exp.fulfill()

        wait(for: [exp], timeout: 1.0)

        let expected = 0
        let actual = fetcher.taskCount
        XCTAssertEqual(expected, actual)
    }
}
