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
        MockURLProtocol.responseProvider = { url in
            (Mock.makeImageData(side: 150), Mock.makeResponse(url: url))
        }
        let fetcher = ImageFetcher(Self.cache, networking: Networking(.mock), imageProcessor: MockImageProcessor())

        let exp = expectation(description: "Finished")
        _ = try await fetcher.load(Mock.baseURL)
        exp.fulfill()

        await fulfillment(of: [exp], timeout: 1.0)

        let expected = 0
        let actual = fetcher.taskCount
        XCTAssertEqual(expected, actual)
    }
}
