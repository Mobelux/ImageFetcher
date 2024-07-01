//
//  TaskManager.swift
//  Mobelux
//
//  MIT License
//
//  Copyright (c) 2024 Mobelux LLC
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

final class TaskManager: @unchecked Sendable {
    private let lock = NSLock()
    private var tasks: [String: Task<ImageSource, Error>] = [:]

    var taskCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return tasks.count
    }

    func insertTask(_ imageFetcherTask: Task<ImageSource, Error>, key: ImageConfiguration) {
        lock.lock()
        defer { lock.unlock() }

        tasks[key.key] = imageFetcherTask
    }

    func getTask(_ key: ImageConfiguration) -> Task<ImageSource, Error>? {
        lock.lock()
        defer { lock.unlock() }

        return tasks[key.key]
    }

    @discardableResult
    func removeTask(_ key: ImageConfiguration) -> Task<ImageSource, Error>? {
        lock.lock()
        defer { lock.unlock() }

        return tasks.removeValue(forKey: key.key)
    }
}
