//
//  Queue.swift
//  Mobelux
//
//  Created by Jeremy Greenwood on 2/7/18.
//  Copyright © 2018 Mobelux. All rights reserved.
//

import Foundation

/// A queue that regulates the execution of operations.
public protocol Queue: AnyObject {
    /// The maximum number of queued operations that can run at the same time.
    var maxConcurrentOperationCount: Int { get set }

    /// Adds the specified operation to the receiver.
    /// - Parameter operation: The operation to be added to the queue.
    func addOperation(_ operation: Operation)

    /// Cancels all queued and executing operations.
    func cancelAllOperations()
}

extension OperationQueue: Queue {}
