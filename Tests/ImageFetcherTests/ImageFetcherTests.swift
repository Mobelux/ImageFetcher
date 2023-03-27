import XCTest
@testable import ImageFetcher

final class ImageFetcherTests: XCTestCase {
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

    func testCompletedTaskRemoval() async throws {
        MockURLProtocol.responseProvider = { url in
            (Mock.makeImageData(side: 150), Mock.makeResponse(url: url))
        }
        let cache = try DiskCache(storageType: .temporary(.custom("\(Date().timeIntervalSince1970)")))
        let fetcher = ImageFetcher(cache, networking: Networking(.mock), imageProcessor: MockImageProcessor())

        let exp = expectation(description: "Finished")
        _ = try await fetcher.load(Mock.baseURL)
        exp.fulfill()

        await fulfillment(of: [exp], timeout: 1.0)

        let expected = 0
        let actual = fetcher.taskCount
        XCTAssertEqual(expected, actual)
    }
}
