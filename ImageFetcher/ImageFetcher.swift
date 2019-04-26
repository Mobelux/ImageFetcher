//
//  ImageFetcher.swift
//  Mobelux
//
//  Created by Jeremy Greenwood on 3/13/18.
//  Copyright © 2018 Mobelux. All rights reserved.
//

import UIKit
import DataOperation
import DiskCache

public final class ImageFetcher: ImageFetching {
    private var queue: Queue
    private var cache: Cache
    private var tasks: Set<ImageFetcherTask> = []
    private var workerQueue = DispatchQueue.global()

    public init(_ cache: Cache, queue: Queue = OperationQueue(), maxConcurrent: Int = 2) {
        self.cache = cache
        self.queue = queue

        self.queue.maxConcurrentOperationCount = maxConcurrent
    }

    /**
     Builds a `ImageLoaderTask`. If the result of the image configuration is cached, `handler` will be called immediately.
     Otherwise a download operation will be kicked off

     - parameters:
     - imageConfiguration: The configuation of the image to be installed.
     - handler: The handler which passes in an `ImageLoaderTask`

     **/
    public func task(_ imageConfiguration: ImageConfiguration, handler: @escaping (ImageFetcherTask) -> ()) {
        workerQueue.async {
            // if data is cached, use it, else use `DataOperation` to fetch image data
            if let cachedData = try? self.cache.data(imageConfiguration.key), let data = cachedData, let image = UIImage(data: data)?.decompressed() {
                handler(ImageFetcherTask(configuration: imageConfiguration, result: .success(.cached(image))))
            } else {
                DispatchQueue.main.async {
                    let operation = DataOperation(request: URLRequest(url: imageConfiguration.url))
                    operation.name = imageConfiguration.key

                    let task = ImageFetcherTask(configuration: imageConfiguration, operation: operation)
                    operation.completionBlock = self.completion(task: task)
                    self.queue.addOperation(operation)

                    handler(task)
                }
            }
        }
    }

    /**
     Loads the `ImageConfiguration`. If the result of the image configuration is cached, `handler` will be called immediately.
     Otherwise a download operation will be kicked off

     - parameters:
     - imageConfiguration: The configuation of the image to be installed.
     - handler: The handler which passes in an `ImageHandler`

     **/
    public func load(_ imageConfiguration: ImageConfiguration, handler: ImageHandler?) {
        task(imageConfiguration) { [unowned self] task in
            if let result = task.result {
                handler?(result)
            } else {
                task.handler = handler
                self.tasks.insert(task)
            }
        }
    }

    public func clear(_ imageConfiguration: ImageConfiguration) {
        guard let task = self[imageConfiguration] else {
            return
        }

        task.cancel()
        task.operation = nil
        task.handler = nil

        tasks.remove(task)
    }

    public subscript (_ imageConfiguration: ImageConfiguration) -> ImageFetcherTask? {
        return tasks.first(where: { (task) -> Bool in
            task.configuration == imageConfiguration
        })
    }
}

extension ImageFetcher {
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

    public func cache(_ image: UIImage, key: Keyable) {
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

    public func load(image key: Keyable) -> UIImage? {
        do {
            guard let cachedData = try? self.cache.data(key.key), let data = cachedData, let image = UIImage(data: data) else {
                return nil
            }

            return image
        }
    }
}

private extension ImageFetcher {
    func completion(task: ImageFetcherTask) -> (() -> ()) {
        guard let operation = task.operation else {
            return {}
        }

        return { [weak operation, weak self] in
            guard let soperation = operation, let sself = self else {
                return
            }

            // grab the operation's result
            guard let result = soperation.result else {
                task.result = .error(.noResult)
                return
            }

            // convert data result to image result
            let imageResult: Result<ResultType<UIImage>, ImageError> = {
                switch result {
                // data was successfully downloaded
                case .success(let data):
                    guard let image = UIImage(data: data), let editedImage = image.edit(configuration: task.configuration) else {
                        return .error(.cannotParse)
                    }

                    sself.cache(editedImage, key: task.configuration)

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

