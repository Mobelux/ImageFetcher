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
    private var tasks: Set<ImageLoaderTask> = []

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
                handler(ImageLoaderTask(configuration: imageConfiguration, result: .success(.cached(image))))
            } else {
                let operation = DataOperation(request: URLRequest(url: imageConfiguration.url))
                operation.name = imageConfiguration.key

                let task = ImageLoaderTask(configuration: imageConfiguration, operation: operation)
                operation.completionBlock = self.completion(task: task)
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
    public func load(_ imageConfiguration: ImageConfiguration, handler: ImageHandler?) {
        task(imageConfiguration) { task in
            if let result = task.result {
                handler?(result)
            } else {
                if let handler = handler {
                    task.handler = handler
                } else {
                    self.tasks.insert(task)

                    task.handler = { [weak self, weak task] result in
                        guard let sself = self, let stask = task else {
                            return
                        }

                        sself.tasks.remove(stask)
                        handler?(result)
                    }
                }
            }
        }
    }

    public func cancel(_ imageConfiguration: ImageConfiguration) {
        let task = self[imageConfiguration]
        task?.cancel()
        task?.handler = nil
    }

    public subscript (_ imageConfiguration: ImageConfiguration) -> ImageLoaderTask? {
        return tasks.first(where: { (task) -> Bool in
            task.configuration == imageConfiguration
        })
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

    func completion(task: ImageLoaderTask) -> (() -> ()) {
        guard let operation = task.operation else {
            return {}
        }

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
                    guard let image = UIImage(data: data), let editedImage = image.edit(configuration: task.configuration) else {
                        return .error(.cannotParse)
                    }

                    self.cache(editedImage, key: task.configuration)

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
