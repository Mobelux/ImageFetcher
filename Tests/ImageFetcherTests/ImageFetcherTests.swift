import XCTest
@testable import ImageFetcher

final class ImageFetcherTests: XCTestCase {
    func testCompletedTaskRemoval() async throws {
        let cache = MockCache(
            onCache: { _, _ in },
            onData: { _ in throw MockCache.CacheError(reason: "File missing") })
        let networking = Networking.mock(responseDelay: 0.1) { _ in Mock.makeImageData(side: 150) }
        let sut = ImageFetcher(cache, networking: networking, imageProcessor: MockImageProcessor())

        let exp = expectation(description: "Finished")
        _ = try await sut.load(Mock.baseURL)
        exp.fulfill()

        await fulfillment(of: [exp], timeout: 1.0)

        let expected = 0
        let actual = sut.taskCount
        XCTAssertEqual(expected, actual)
    }

    func testContinuationsAreNotLeaked() async throws {
        let cache = MockCache(
            onCache: { _, _ in },
            onData: { _ in throw MockCache.CacheError(reason: "File missing") })
        let networking = Networking.mock(responseDelay: 1.0) { _ in Mock.makeImageData(side: 150) }
        let sut = ImageFetcher(cache, networking: networking, imageProcessor: MockImageProcessor())

        let url = URL(string: "https://example.com")!

        let exp = expectation(description: "Request threw error")
        Task {
            do {
                _ = try await sut.load(url)
            } catch {
                XCTAssert(error is CancellationError)
                exp.fulfill()
            }
        }

        try await Task.sleep(nanoseconds: 500_000)
        sut.cancel(url)

        await fulfillment(of: [exp], timeout: 1.0)
    }

    func testSubscriptAccessThreadSafety() async throws {
        let requestCount: Int = 100

        let cache = MockCache(
            onCache: { _, _ in },
            onData: { _ in throw MockCache.CacheError(reason: "File missing") })
        let networking = Networking.mock(responseDelay: 0.1) { _ in Mock.makeImageData(side: 100) }
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

    func testCancelNonexistentTask() async {
        let sut = ImageFetcher(MockCache(), networking: Networking.mock(), imageProcessor: MockImageProcessor())
        sut.cancel(ImageConfiguration(url: Mock.makeURL()))
    }
}

// MARK: - Task Functionality
extension ImageFetcherTests {
    func testGetExistingTask() async throws {
        var readCount = 0
        let cache = MockCache(
            onCache: { _, _ in },
            onData: { _ in
                readCount += 1
                throw MockCache.CacheError(reason: "File missing")
            })

        var requestCount = 0
        let networking = Networking.mock(responseDelay: 1.0) { _ in
            requestCount += 1
            return Mock.makeImageData(side: 100)

        }
        let sut = ImageFetcher(cache, networking: networking, imageProcessor: MockImageProcessor())

        let imageURL = Mock.makeURL()

        async let task1 = await sut.task(imageURL)
        try await Task.sleep(nanoseconds: 500_000_000)
        async let task2 = await sut.task(imageURL)

        let (imageSource1, imageSource2) = try await (task1.value, task2.value)
        XCTAssertEqual(imageSource1.value.pngData()!, imageSource2.value.pngData()!)
        XCTAssertEqual(readCount, 1)
        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(sut.taskCount, 0)
    }

    func testGetDecompressTask() async throws {
        let imageData = Mock.makeImageData(side: 300)

        let readExpectation = expectation(description: "Cached image read")
        let cache = MockCache(
            onCache: { _, _ in },
            onData: { _ in
                defer { readExpectation.fulfill() }
                return imageData
            })

        let requestExpectation = expectation(description: "Image fetched")
        requestExpectation.isInverted = true
        let networking = Networking.mock { _ in
            requestExpectation.fulfill()
            return Mock.makeImageData(side: 100)
        }

        let sut = ImageFetcher(cache, networking: networking, imageProcessor: MockImageProcessor())

        let imageURL = Mock.makeURL()
        async let task1 = await sut.task(imageURL)

        await fulfillment(of: [readExpectation, requestExpectation], timeout: 0.5)
        let image = try await task1.value
        XCTAssertEqual(image.value.pngData()!, imageData)
    }
}

// MARK: - Cache Functionality
extension ImageFetcherTests {
    func testDeleteCache() async throws {
        let deletionExpectation = expectation(description: "Cache deleted")
        let cache = MockCache(onDeleteAll: {
            deletionExpectation.fulfill()
        })

        let sut = ImageFetcher(cache, imageProcessor: MockImageProcessor())
        try await sut.deleteCache()
        await fulfillment(of: [deletionExpectation])
    }

    func testDeleteURL() async throws {
        var deletedKey: String!
        let deletionExpectation = expectation(description: "Cached image deleted")
        let cache = MockCache(onDelete: { key in
            deletedKey = key
            deletionExpectation.fulfill()
        })

        let imageURL = Mock.baseURL.appendingPathComponent("foo.png")

        let sut = ImageFetcher(cache, imageProcessor: MockImageProcessor())
        try await sut.delete(imageURL)
        await fulfillment(of: [deletionExpectation])
        XCTAssertEqual(deletedKey, ImageConfiguration(url: imageURL).key)
    }

    func testDeleteConfiguration() async throws {
        var deletedKey: String!
        let deletionExpectation = expectation(description: "Cached image deleted")
        let cache = MockCache(onDelete: { key in
            deletedKey = key
            deletionExpectation.fulfill()
        })

        let imageConfig = ImageConfiguration(url: Mock.makeURL())

        let sut = ImageFetcher(cache, imageProcessor: MockImageProcessor())
        try await sut.delete(imageConfig)
        await fulfillment(of: [deletionExpectation])
        XCTAssertEqual(deletedKey, imageConfig.key)
    }

    func testCacheURL() async throws {
        var cachedData: Data!
        var cachedKey: String!
        let cacheExpectation = expectation(description: "Image cached")
        let cache = MockCache(onCache: { data, key in
            cachedData = data
            cachedKey = key
            cacheExpectation.fulfill()
        })

        let image = Color.random().image(CGSize(width: 250, height: 250))
        let imageURL = Mock.baseURL.appendingPathComponent("foo.png")

        let sut = ImageFetcher(cache, imageProcessor: MockImageProcessor())
        try await sut.cache(image, key: imageURL)
        await fulfillment(of: [cacheExpectation])
        XCTAssertEqual(cachedData, image.pngData())
        XCTAssertEqual(cachedKey, ImageConfiguration(url: imageURL).key)
    }

    func testCacheConfiguration() async throws {
        var cachedData: Data!
        var cachedKey: String!
        let cacheExpectation = expectation(description: "Image cached")
        let cache = MockCache(onCache: { data, key in
            cachedData = data
            cachedKey = key
            cacheExpectation.fulfill()
        })

        let image = Color.random().image(CGSize(width: 250, height: 250))
        let imageURL = Mock.baseURL.appendingPathComponent("foo.png")
        let imageConfig = ImageConfiguration(url: imageURL)

        let sut = ImageFetcher(cache, imageProcessor: MockImageProcessor())
        try await sut.cache(image, key: imageConfig)
        await fulfillment(of: [cacheExpectation])
        XCTAssertEqual(cachedData, image.pngData())
        XCTAssertEqual(cachedKey, imageConfig.key)
    }

    func testLoadURLFromCache() async {
        let imageData = Mock.makeImageData(side: 300)
        let imageURL = Mock.baseURL.appendingPathComponent("foo.png")

        // Cache
        var imageKey: String!
        let loadExpectation = expectation(description: "Cached image loaded")
        let cache = MockCache(onData: { key in
            defer { loadExpectation.fulfill() }
            imageKey = key
            return imageData
        })

        // Image Processor
        let decompressExpectation = expectation(description: "Image data decompressed")
        let imageProcessor = MockImageProcessor(onDecompress: { processedData in
            defer { decompressExpectation.fulfill() }
            XCTAssertEqual(processedData, imageData)
            return Image(data: imageData)!
        })

        let sut = ImageFetcher(cache, imageProcessor: imageProcessor)
        let actualImage = await sut.load(image: imageURL)

        await fulfillment(of: [loadExpectation, decompressExpectation])
        XCTAssertEqual(imageKey, ImageConfiguration(url: imageURL).key)
        XCTAssertEqual(actualImage!.pngData()!, imageData)
    }

    func testLoadConfigurationFromCache() async throws {
        let imageData = Mock.makeImageData(side: 300)
        let imageURL = Mock.baseURL.appendingPathComponent("foo.png")
        let imageConfig = ImageConfiguration(url: imageURL)

        // Cache
        var imageKey: String!
        let loadExpectation = expectation(description: "Cached image loaded")
        let cache = MockCache(onData: { key in
            defer { loadExpectation.fulfill() }
            imageKey = key
            return imageData
        })

        // Image Processor
        let decompressExpectation = expectation(description: "Image data decompressed")
        let imageProcessor = MockImageProcessor(onDecompress: { processedData in
            defer { decompressExpectation.fulfill() }
            XCTAssertEqual(processedData, imageData)
            return Image(data: imageData)!
        })

        let sut = ImageFetcher(cache, imageProcessor: imageProcessor)
        let actualImage = await sut.load(image: imageConfig)

        await fulfillment(of: [loadExpectation, decompressExpectation])
        XCTAssertEqual(imageKey, imageConfig.key)
        XCTAssertEqual(actualImage!.pngData()!, imageData)
    }

    func testLoadUncachedFromCache() async throws {
        let imageConfig = ImageConfiguration(url: Mock.baseURL.appendingPathComponent("foo.png"))

        // Cache
        var imageKey: String!
        let loadExpectation = expectation(description: "Cached image loaded")
        let cache = MockCache(onData: { key in
            defer { loadExpectation.fulfill() }
            imageKey = key
            throw MockCache.CacheError(reason: "File missing")
        })

        // Image Processor
        let imageProcessor = MockImageProcessor(onDecompress: { data in
            XCTFail("Image decompressed")
            return Color.random().image()
        })

        let sut = ImageFetcher(cache, imageProcessor: imageProcessor)
        let actualImage = await sut.load(image: imageConfig)

        await fulfillment(of: [loadExpectation], timeout: 0.5)
        XCTAssertEqual(imageKey, imageConfig.key)
        XCTAssertNil(actualImage)
    }
}
