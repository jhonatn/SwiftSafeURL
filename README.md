# SafeURL

Tool for avoiding using the `URL(string:)` initializer with optional result, instead introducing a compile time URL validity check. Note, this does not check for website availability, but if the URL is formatted correctly.

## Installation

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. 

Once you have your Swift package set up, adding SafeURL as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/baguio/SwiftSafeURL")
],
targets: [
    .target(
        name: "<MyTargetName>",
        dependencies: ["SafeURL"],
        plugins: ["SafeURLPlugin"]
    ),
]
```

## Example

```swift
// This will compile
let validUrl = URL(safeString: "https://example.tld")
// This won't
let invalidUrl = URL(safeString: "https://example./tld")
```

SafeURL requires its parameter to be a single simple string literal 
