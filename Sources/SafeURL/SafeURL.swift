import Foundation

public extension URL {
    init(safeString: String) {
        self.init(string: safeString)!
    }
}
