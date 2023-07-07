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

class MockCache: Cache {
    struct CacheError: Error {
        let reason: String
    }

    var onCache: ((Data, String) throws -> ())?
    var onData: ((String) throws -> Data)?
    var onDelete: ((String) throws -> ())?
    var onDeleteAll: (() throws -> ())?
    var onFileURL: ((String) -> URL)?

    init(
        onCache: ((Data, String) throws -> ())? = nil,
        onData: ((String) throws -> Data)? = nil,
        onDelete: ((String) throws -> ())? = nil,
        onDeleteAll: (() throws -> ())? = nil,
        onFileURL: ((String) -> URL)? = nil
    ) {
        self.onCache = onCache
        self.onData = onData
        self.onDelete = onDelete
        self.onDeleteAll = onDeleteAll
        self.onFileURL = onFileURL
    }

    func syncCache(_ data: Data, key: String) throws {
        if let onCache {
            try onCache(data, key)
        } else {
            XCTFail("MockCache.\(#function)")
        }
    }

    func syncData(_ key: String) throws -> Data {
        if let onData {
            return try onData(key)
        } else {
            XCTFail("MockCache.\(#function)"); return Data()
        }
    }

    func syncDelete(_ key: String) throws {
        if let onDelete {
            try onDelete(key)
        } else {
            XCTFail("MockCache.\(#function)")
        }
    }

    func syncDeleteAll() throws {
        if let onDeleteAll {
            try onDeleteAll()
        } else {
            XCTFail("MockCache.\(#function)")
        }
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
            try onCache(data, key)
        } else {
            XCTFail("MockCache.\(#function)")
        }
    }

    func data(_ key: String) async throws -> Data {
        if let onData {
            return try onData(key)
        } else {
            XCTFail("MockCache.\(#function)"); return Data()
        }
    }

    func delete(_ key: String) async throws {
        if let onDelete {
            try onDelete(key)
        } else {
            XCTFail("MockCache.\(#function)")
        }
    }

    func deleteAll() async throws {
        if let onDeleteAll {
            try onDeleteAll()
        } else {
            XCTFail("MockCache.\(#function)")
        }
    }
}
