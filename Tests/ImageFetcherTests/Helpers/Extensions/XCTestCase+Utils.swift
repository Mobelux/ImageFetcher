//
//  XCTestCase+Utils.swift
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
import XCTest

#if swift(<5.8)
extension XCTestCase {
    /// Waits on a group of expectations for up to the specified timeout, optionally enforcing their order of fulfillment.
    ///
    /// This allows use of Xcode 14.3's `XCTestCase.fulfillment(of:timeout:enforceOrder:)` method while maintaining
    /// compatibility with previous versions.
    ///
    /// - Parameters:
    ///   - expectations: An array of expectations the test must satisfy.
    ///   - seconds: The time, in seconds, the test allows for the fulfillment of the expectations. The default timeout
    ///   allows the test to run until it reaches its execution time allowance.
    ///   - enforceOrderOfFulfillment: If `true`, the test must satisfy the expectations in the order they appear in
    ///   the array.
    func fulfillment(
        of expectations: [XCTestExpectation],
        timeout seconds: TimeInterval = .infinity,
        enforceOrder enforceOrderOfFulfillment: Bool = false
    ) async {
        await MainActor.run {
            wait(for: expectations, timeout: seconds, enforceOrder: enforceOrderOfFulfillment)
        }
    }
}
#endif
