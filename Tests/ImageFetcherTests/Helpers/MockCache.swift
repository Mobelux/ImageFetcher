//
//  MockCache.swift
//  Mobelux
//
//  MIT License
//
//  Copyright (c) 2023 Mobelux LLC
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import ImageFetcher
import XCTest

final class MockCache: Cache {
    struct CacheError: Error {
        let reason: String
    }

    let onCache: (@Sendable (Data, String) async throws -> Void)?
    let onData: (@Sendable (String) async throws -> Data)?
    let onDelete: (@Sendable (String) async throws -> Void)?
    let onDeleteAll: (@Sendable () async throws -> Void)?
    let onFileURL: (@Sendable (String) -> URL)?

    init(
        onCache: (@Sendable (Data, String) async throws -> Void)? = nil,
        onData: (@Sendable (String) async throws -> Data)? = nil,
        onDelete: (@Sendable (String) async throws -> Void)? = nil,
        onDeleteAll: (@Sendable () async throws -> Void)? = nil,
        onFileURL: (@Sendable (String) -> URL)? = nil
    ) {
        self.onCache = onCache
        self.onData = onData
        self.onDelete = onDelete
        self.onDeleteAll = onDeleteAll
        self.onFileURL = onFileURL
    }

    func syncCache(_ data: Data, key: String) throws {
        XCTFail("Unimplemented")
    }

    func syncData(_ key: String) throws -> Data {
        XCTFail("Unimplemented")
        return Mock.makeImageData(side: 300)
    }

    func syncDelete(_ key: String) throws {
        XCTFail("Unimplemented")
    }

    func syncDeleteAll() throws {
        XCTFail("Unimplemented")
    }

    func fileURL(_ key: String) -> URL {
        if let onFileURL {
            return onFileURL(key)
        } else {
            XCTFail("MockCache.\(#function)"); return URL(fileURLWithPath: "")
        }
    }

    // Async support

    func cache(_ data: Data, key: String) async throws {
        if let onCache {
            try await onCache(data, key)
        } else {
            XCTFail("MockCache.\(#function)")
        }
    }

    func data(_ key: String) async throws -> Data {
        if let onData {
            return try await onData(key)
        } else {
            XCTFail("MockCache.\(#function)"); return Data()
        }
    }

    func delete(_ key: String) async throws {
        if let onDelete {
            try await onDelete(key)
        } else {
            XCTFail("MockCache.\(#function)")
        }
    }

    func deleteAll() async throws {
        if let onDeleteAll {
            try await onDeleteAll()
        } else {
            XCTFail("MockCache.\(#function)")
        }
    }
}
