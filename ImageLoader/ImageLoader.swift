//
//  ImageLoader.swift
//  Mobelux
//
//  Created by Jeremy Greenwood on 3/13/18.
//  Copyright © 2018 Mobelux. All rights reserved.
//

import UIKit
import DataOperation
import DiskCache

public final class ImageLoader {
    private var queue: Queue
    private var cache: Cache

    public init(_ queue: Queue = OperationQueue(), cache: Cache = DiskCache(storageType: .temporary)) {
        self.cache = cache
        self.queue = queue

        self.queue.maxConcurrentOperationCount = 2
    }

    /**
     Builds a `ImageLoaderTask`. If the result of the image configuration is cached, `handler` will be called immediately.
     Otherwise a download operation will be kicked off

     - parameters:
     - imageConfiguration: The configuation of the image to be installed.
     - handler: The handler which passes in an `ImageLoaderTask`

     - Note: Handler always gets called on an arbitrary background queue

     **/
    public func task(_ imageConfiguration: ImageConfiguration, handler: @escaping (ImageLoaderTask) -> ()) {
        DispatchQueue.global(qos: .background).async {
            // if data is cached, use it, else use `DataOperation` to fetch image data
            if let cachedData = try? self.cache.data(imageConfiguration.key), let data = cachedData, let image = UIImage(data: data) {
                handler(ImageLoaderTask(result: .success(.cached(image))))
            } else {
                let operation = DataOperation(request: URLRequest(url: imageConfiguration.url))
                operation.name = imageConfiguration.key

                let task = ImageLoaderTask(operation: operation)
                operation.completionBlock = self.completion(for: operation, imageConfiguration: imageConfiguration, task: task)
                self.queue.addOperation(operation)

                handler(task)
            }
        }
    }

    /**
     Loads the `ImageConfiguration`. If the result of the image configuration is cached, `handler` will be called immediately.
     Otherwise a download operation will be kicked off

     - parameters:
     - imageConfiguration: The configuation of the image to be installed.
     - handler: The handler which passes in an `ImageHandler`

     - Note: Handler always gets called on an arbitrary background queue

     **/
    public func load(_ imageConfiguration: ImageConfiguration, handler: @escaping ImageHandler) {
        task(imageConfiguration) { task in
            if let result = task.result {
                handler(result)
            } else {
                task.handler = handler
            }
        }
    }
}

extension ImageLoader {
    /*
     Deletes image configuration from the cache
     */
    public func delete(_ imageConfiguration: ImageConfiguration) {
        do {
            try cache.delete(imageConfiguration.key)
        } catch {
            print("\(#function) - \(error.localizedDescription)")
        }
    }
}

private extension ImageLoader {
    func cache(_ image: UIImage, key: Keyable) {
        // cache image data, if fails only print error
        do {
            guard let data = UIImagePNGRepresentation(image) else {
                print("\(#function) - Could not convert image to PNG")
                return
            }

            try self.cache.cache(data, key: key.key)
        } catch {
            print("\(#function) - \(error.localizedDescription)")
        }
    }

    func completion(for operation: DataOperation, imageConfiguration: ImageConfiguration, task: ImageLoaderTask) -> (() -> ()) {
        return { [weak operation, unowned self] in
            // grab the operation's result
            guard let result = operation?.result else {
                task.result = .error(.noResult)
                return
            }

            // convert data result to image result
            let imageResult: Result<ResultType<UIImage>, ImageError> = {
                switch result {
                // data was successfully downloaded
                case .success(let data):
                    guard let image = UIImage(data: data), let editedImage = image.edit(configuration: imageConfiguration) else {
                        return .error(.cannotParse)
                    }

                    self.cache(editedImage, key: imageConfiguration)

                    return .success(.downloaded(editedImage))
                case .error(let error):
                    return .error(ImageError.convertFrom(error))
                }
            }()

            // call the handle with an image result
            task.result = imageResult
        }
    }
}

