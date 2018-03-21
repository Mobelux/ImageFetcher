//
//  ImageLoaderTask.swift
//  Mobelux
//
//  Created by Jeremy Greenwood on 2/8/18.
//  Copyright © 2018 Mobelux. All rights reserved.
//

import UIKit
import DataOperation

public typealias ImageHandler = (Result<ResultType<UIImage>, ImageError>) -> ()

public final class ImageLoaderTask {
    var operation: DataOperation?

    public var handler: ImageHandler?
    public var configuration: ImageConfiguration
    public var result: Result<ResultType<UIImage>, ImageError>? {
        didSet {
            guard let result = result else {
                return
            }

            handler?(result)
            operation = nil
        }
    }

    public init(configuration: ImageConfiguration, operation: DataOperation? = nil, result: Result<ResultType<UIImage>, ImageError>? = nil) {
        self.configuration = configuration
        self.operation = operation
        self.result = result
    }

    public func cancel() {
        operation?.cancel()
        operation = nil
    }
}

extension ImageLoaderTask: Equatable {
    static public func == (lhs: ImageLoaderTask, rhs: ImageLoaderTask) -> Bool {
        return lhs.configuration == rhs.configuration &&
        lhs.operation == rhs.operation
    }
}

extension ImageLoaderTask: Hashable {
    public var hashValue: Int {
        return configuration.key.hashValue
    }
}
