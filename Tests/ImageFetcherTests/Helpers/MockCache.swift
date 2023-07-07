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

class MockCache: Cache {
    struct CacheError: Error {
        let reason: String
    }

    var onCache: (Data, String) throws -> ()
    var onData: (String) throws -> Data
    var onDelete: (String) throws -> ()
    var onDeleteAll: () throws -> ()
    var onFileURL: (String) -> URL

    init(
        onCache: @escaping (Data, String) throws -> () = { _, _ in },
        onData: @escaping (String) throws -> Data = { _ in Data() },
        onDelete: @escaping (String) throws -> () = { _ in },
        onDeleteAll: @escaping () throws -> () = { },
        onFileURL: @escaping (String) -> URL = { _ in URL(fileURLWithPath: "") }
    ) {
        self.onCache = onCache
        self.onData = onData
        self.onDelete = onDelete
        self.onDeleteAll = onDeleteAll
        self.onFileURL = onFileURL
    }

    func syncCache(_ data: Data, key: String) throws {
        try onCache(data, key)
    }

    func syncData(_ key: String) throws -> Data {
        try onData(key)
    }

    func syncDelete(_ key: String) throws {
        try onDelete(key)
    }

    func syncDeleteAll() throws {
        try onDeleteAll()
    }

    func fileURL(_ key: String) -> URL {
        onFileURL(key)
    }

    // Async support

    func cache(_ data: Data, key: String) async throws {
        try onCache(data, key)
    }

    func data(_ key: String) async throws -> Data {
        try onData(key)
    }

    func delete(_ key: String) async throws {
        try onDelete(key)
    }

    func deleteAll() async throws {
        try onDeleteAll()
    }
}
