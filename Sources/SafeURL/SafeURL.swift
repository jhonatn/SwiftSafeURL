import Foundation

public extension URL {
    init(safeString: StaticString) {
        self.init(string: "\(safeString)")!
    }
}
