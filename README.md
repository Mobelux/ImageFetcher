# ImageFetcher

ImageFetcher is lightweight image loading library. It is optimizes for scroll view performance by decompressing images in the background and exposing a configuration option for rounding corners of the image.

## 📱 Requirements

Swift 5.5 toolchain with Swift Package Manager, iOS 13

## 🖥 Installation

### 📦 Swift Package Manager (recommended)

Add `ImageFetcher` to your `Packages.swift` file:

```swift
.package(url: "https://github.com/Mobelux/ImageFetcher.git", from: "2.0.0"),
```

## ⚙️ Usage

Intialize `ImageFetcher` with a `Cache`:

```swift
let fetcher = ImageFetcher(try DiskCache(storageType: .temporary(nil)))
```

Optionally initialize with a session configuration and maximum concurrent image processing operation count:

```swift
let sessionConfiguration = URLSessionConfiguration.default
sessionConfiguration.timeoutIntervalForResource = 20
let fetcher = ImageFetcher(try DiskCache(storageType: .temporary(nil)),
                           sessionConfiguration: sessionConfiguration,
                           maxConcurrent: 5)
```

To fetch an image from the web:

```swift
let config = ImageConfiguration(url: URL(string: "https://via.placeholder.com/150")!)
let image = try await fetcher.load(config).value
```

Fetch an image with configuration options and robust handling:

```swift
let config = ImageConfiguration(url: URL(string: "https://via.placeholder.com/150")!,
                                size: CGSize(width: 100.0, height: 100.0),
                                constrain: true,
                                cornerRadius: 10.0,
                                scale: 1)
do {
    let imageSource = try await fetcher.load(config)
    switch imageSource {
    case .cached(let image):
        /// handle image coming from cache
    case .downloaded(let image):
        /// handle newly downloaded image
    }
} catch {
    /// handle error
}
```

## License

ImageFetcher is release under MIT licensing.
