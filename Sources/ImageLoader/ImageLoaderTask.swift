//
//  ImageLoaderTask.swift
//  Mobelux
//
//  Created by Jeremy Greenwood on 2/8/18.
//  Copyright © 2018 Mobelux. All rights reserved.
//

import UIKit
import DataOperation

typealias ImageHandler = (Result<ResultType<UIImage>, ImageError>) -> ()

final class ImageLoaderTask {
    private var operation: DataOperation?

    var handler: ImageHandler?
    var result: Result<ResultType<UIImage>, ImageError>? {
        didSet {
            guard let result = result else {
                return
            }

            handler?(result)
            operation = nil
        }
    }

    init(operation: DataOperation? = nil, result: Result<ResultType<UIImage>, ImageError>? = nil) {
        self.operation = operation
        self.result = result
    }

    func cancel() {
        operation?.cancel()
        operation = nil
    }
}
