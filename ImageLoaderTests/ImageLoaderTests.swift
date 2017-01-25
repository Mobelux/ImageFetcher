//
//  ImageLoaderTests.swift
//  ImageLoaderTests
//
//  Created by Jerry Mayers on 11/2/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import XCTest
@testable import ImageLoader

class ImageLoaderTests: XCTestCase {

    private var cache: URLCache?

    override func setUp() {
        super.setUp()
        cache?.removeAllCachedResponses()
    }
    
    override func tearDown() {
        cache?.removeAllCachedResponses()
        super.tearDown()
    }

    private func configureLoader() -> (ImageLoader, Session, MockReachability) {
        let reachable = MockReachability()
        let cache = URLCache(memoryCapacity: 100 * 1024 * 1024, diskCapacity: 0, diskPath: nil)
        self.cache = cache
        let session = MockSession(reachable: reachable, cache: cache)
        let loader = ImageLoader(session: session, cache: cache, reachable: reachable)
        return (loader, session, reachable)
    }
    
    func testBasicImage() {
        let (loader, _, _) = configureLoader()
        let imageURL = URL(string: "http://mobelux.com/static/img/mobelux-mark.99537226e971.png")!

        let loadingExpectation = expectation(description: "Basic image")

        let task = loader.image(from: imageURL) { (image, fromCache) in
            XCTAssertNotNil(image, "Didn't load the image")
            XCTAssertFalse(fromCache, "First request should not be from the cache")

            let task2 = loader.image(from: imageURL) { (image2, fromCache2) in
                XCTAssertNotNil(image2, "Didn't load the image")
                XCTAssert(fromCache2, "Second request should be from the cache")

                loadingExpectation.fulfill()
            }

            XCTAssert(task2.url == imageURL, "URLs don't match")
            XCTAssertFalse(task2.cancelled, "Task started as cancelled")
        }

        XCTAssert(task.url == imageURL, "URLs don't match")
        XCTAssertFalse(task.cancelled, "Task started as cancelled")

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testCancellation() {
        let (loader, _, _) = configureLoader()
        let imageURL = URL(string: "http://mobelux.com/static/img/whoweare/banner-office2.66d4212c95ce.jpg")!

        let loadingExpectation = expectation(description: "Image cancellation")

        var task = loader.image(from: imageURL) { (image, fromCache) in
            XCTAssert(false, "Task was cancelled, we should never get this response")
        }

        XCTAssert(task.url == imageURL, "URLs don't match")
        XCTAssertFalse(task.cancelled, "Task started as cancelled")
        task.cancel()
        XCTAssert(task.cancelled, "Task didn't cancel")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            loadingExpectation.fulfill()
        }
        waitForExpectations(timeout: 4, handler: nil)
    }

    func testWhenNetworkNotReachable() {
        let (loader, _, reachable) = configureLoader()
        let imageURL = URL(string: "http://mobelux.com/static/img/mobelux-mark.99537226e971.png")!

        let loadingExpectation = expectation(description: "Reachable testing")

        reachable.isReachable = false

        let task = loader.image(from: imageURL) { (image, fromCache) in
            XCTAssertNil(image, "Loaded the image, but network is down. Why did this work???")
            reachable.isReachable = true

            let task2 = loader.image(from: imageURL) { (image2, fromCache2) in
                XCTAssertNotNil(image2, "Didn't load the image")
                XCTAssertFalse(fromCache2, "Second request should be from the network")

                reachable.isReachable = false

                let _ = loader.image(from: imageURL) { (image3, fromCache3) in
                    XCTAssertNotNil(image3, "Didn't load the image")
                    XCTAssert(fromCache3, "This request should be from the cache")

                    loadingExpectation.fulfill()
                }
            }

            XCTAssert(task2.url == imageURL, "URLs don't match")
            XCTAssertFalse(task2.cancelled, "Task started as cancelled")
        }

        XCTAssert(task.url == imageURL, "URLs don't match")
        XCTAssertFalse(task.cancelled, "Task started as cancelled")
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
}