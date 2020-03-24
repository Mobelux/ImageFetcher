# ImageFetcher

ImageFetcher is lightweight image loading library build on top of `OperationQueue`. It is optimizes for scroll view performance by decompressing images in the background and exposing a configuration option for rounding corners of the image.

## 📱 Requirements

Swift 5.1x toolchain with Swift Package Manager, iOS 12

## 🖥 Installation

### 📦 Swift Package Manager (recommended)

Add `ImageFetcher` to your `Packages.swift` file:

```swift
.package(url: "https://github.com/Mobelux/ImageFetcher.git", from: "1.0.0"),
```

## ⚙️ Usage

Intialize `ImageFetcher` with a `Cache`:

```swift
let fetcher = try ImageFetcher(DiskCache(storageType: .temporary(nil)))
```

Optionally initialize with a queue and maximum concurrent download count:

```swift
let fetcher = try ImageFetcher(DiskCache(storageType: .temporary(nil)), queue: OperationQueue(), maxConcurrent: 5)
```

To fetch an image from the web:

```swift
let config = ImageConfiguration(url: URL(string: "https://via.placeholder.com/150")!)
fetcher.load(config) { result in
    switch result {
    case .success(let imageResult):
        let image = imageResult.value
    default: break
    }
}
```

Fetch an image with configuration options and robust handling:

```swift
let config = ImageConfiguration(url: URL(string: "https://via.placeholder.com/150")!,
                                size: CGSize(width: 100.0, height: 100.0),
                                constrain: true,
                                cornerRadius: 10.0,
                                scale: 1)
fetcher.load(config) { result in
    switch result {
    case .success(let imageResult):
        switch imageResult {
        case .cached(let image):
            /// handle image coming from cache
        case .downloaded(let image):
            /// handle newly downloaded image
        }
    case .failure(let error):
        /// handle error
    }
}
```

## License

ImageFetcher is release under MIT licensing.
