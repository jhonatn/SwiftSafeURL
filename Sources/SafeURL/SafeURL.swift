import Foundation

public extension URL {
    /// Initialize with string. Internally uses `URL.init(string:)`
    ///
    /// Shows an error if a `URL` cannot be formed with the string (for example, if the string contains characters that are illegal in a URL, or is an empty string).
    /// If the file contains the comment `// safeurl:warn`, invalid `URL`s will be compiled, showing a warning instead of an error. Note that this is not recommended, as this will still force-stop the executable on runtime.
    init(safeString: StaticString) {
        self.init(string: "\(safeString)")!
    }
}
