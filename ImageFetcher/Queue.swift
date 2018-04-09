//
//  Queue.swift
//  Mobelux
//
//  Created by Jeremy Greenwood on 2/7/18.
//  Copyright © 2018 Mobelux. All rights reserved.
//

import Foundation

public protocol Queue {
    var maxConcurrentOperationCount: Int { get set }

    init()
    func addOperation(_ operation: Operation)
    func cancelAllOperations()
}

extension OperationQueue: Queue {}
