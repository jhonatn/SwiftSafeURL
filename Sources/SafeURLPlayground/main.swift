import Foundation
import SafeURL

// MARK: Valid URLs
_ = URL(safeString: "127.0.0.1")
_ = URL(safeString: "localhost")
_ = URL(safeString: "http://google.com")
_ = URL(safeString: "https://google.com")
_ = URL(safeString: "git@github.com:apple/swift.git")

// MARK: Unvalid input
_ = URL(safeString: "")
_ = URL(safeString: "bjignuoergnig3j894j8023f444qf@Q#C$T@B^UN&I$")

// MARK: SafeURL requirement error
_ = URL(safeString: "http://\u{1F600}.test")
