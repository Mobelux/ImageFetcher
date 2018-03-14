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
    private var operation: DataOperation?

    public var handler: ImageHandler?
    public var result: Result<ResultType<UIImage>, ImageError>? {
        didSet {
            guard let result = result else {
                return
            }

            handler?(result)
            operation = nil
        }
    }

    public init(operation: DataOperation? = nil, result: Result<ResultType<UIImage>, ImageError>? = nil) {
        self.operation = operation
        self.result = result
    }

    public func cancel() {
        operation?.cancel()
        operation = nil
    }
}
