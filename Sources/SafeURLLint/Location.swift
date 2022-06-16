import Foundation
import SourceKittenFramework

/// The placement of a segment of Swift in a collection of source files.
struct Location: Codable {
    /// The file path on disk for this location.
    let file: String?
    /// The line offset in the file for this location. 1-indexed.
    let line: Int?
    /// The character offset in the file for this location. 1-indexed.
    let columnStart: Int?
    let columnEnd: Int?

    /// The file path for this location relative to the current working directory.
    var relativeFile: String? {
        return file?.replacingOccurrences(of: FileManager.default.currentDirectoryPath + "/", with: "")
    }

    /// Creates a `Location` based on a `SwiftLintFile` and a byte-offset into the file.
    /// Fails if the specified offset was not a valid location in the file.
    init?(file: SourceKittenFramework.File, byteRange: ByteRange) {
        self.file = file.path
        guard let _line = file.stringView.lineAndCharacter(forByteOffset: byteRange.lowerBound)?.line, let range = file.stringView.lineRangeWithByteRange(byteRange) else {
            return nil
        }
        line = _line
        columnStart = range.start
        columnEnd = range.end
    }
}
