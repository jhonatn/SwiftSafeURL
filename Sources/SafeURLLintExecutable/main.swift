import Foundation
import SafeURLLintFramework

let args = ProcessInfo().arguments

guard args.count > 1 else {
    exit(1)
}

let filePath = args[1]

guard let scanInfo = try SafeURLKit.preScanShowsPossibleReports(file: filePath) else {
    exit(1)
}

let result = try SafeURLKit.scanAndReport(scanInfo)

exit(result ? 1 : 0)
