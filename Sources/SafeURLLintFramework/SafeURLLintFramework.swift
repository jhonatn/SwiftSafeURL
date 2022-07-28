import Foundation
import SourceKittenFramework
import XcodeIssueReporting
import XcodeIssueReportingForSourceKitten

private let quotesAsCharSet = CharacterSet(arrayLiteral: "\"")
private let expectedParameterName = "safeString"
private let unvalidSafeInputRegexes = [
    (rule: #".+(?<!\\)\".+"#, description: "Non-escaped string delimiter mid-string"),
    (rule: #".+(?<!\\)\\u\{.+"#, description: "Interpolation")
    ]
private let pattern = #"URL\s*\(\s*"# + expectedParameterName + #"\s*:\s*""#

private let disablerComment = #"//\s*safeurl:disable"#
private let warnModeComment = #"//\s*safeurl:warn"#

typealias SourceKittenSubstructure = [SourceKittenDictionary]

public class SafeURLScanInfo {
    let filePath: String
    let fileContent: String
    let scanMode: XcodeIssueType
    
    init(filePath: String, fileContent: String, scanMode: XcodeIssueType) {
        self.filePath = filePath
        self.fileContent = fileContent
        self.scanMode = scanMode
    }
}

public class SafeURLKit {
    private typealias RawLintViolation = (location: XcodeIssueLocation, ruleDescription: String?)
    
    private static func prepareSourceKitten() {
        setenv("IN_PROCESS_SOURCEKIT", "YES", 1) // Necessary for running within a plugin sandbox
    }
    
    private static func extractSafeURLArgumentFromValidSubstructure(_ substructure: SourceKittenSubstructure) -> SourceKittenDictionary? {
        let arguments = substructure.filter { $0.expressionKind == .argument }
        if arguments.count != 1 {
            return nil
        }
        return arguments.first { $0.name == expectedParameterName }
    }
    
    public static func preScanShowsPossibleReports(file filePath: String) throws -> SafeURLScanInfo? {
        let fileURL = URL(fileURLWithPath: filePath)
        let contents = try String(contentsOf: fileURL)
        
        if let _ = contents.range(of: disablerComment, options: .regularExpression, range: nil) {
            return nil
        }
        
        guard let _ = contents.range(of: pattern, options: .regularExpression, range: nil) else {
            return nil
        }
        
        let containsWarnModeComment = contents.range(of: warnModeComment, options: .regularExpression, range: nil) != nil
        return SafeURLScanInfo(
            filePath: filePath,
            fileContent: contents,
            scanMode: containsWarnModeComment ? .warning : .error
        )
    }
    
    public static func scanAndReport(_ scanInfo: SafeURLScanInfo) throws -> Int {
        prepareSourceKitten()
        
        let skFile = SourceKittenFramework.File(contents: scanInfo.fileContent)
        let skStructure = try SourceKittenFramework.Structure(file: skFile)
        let skd = skStructure.readableDictionary()

        let urlDeclarations: [SourceKittenSubstructure] = skd.flatten().compactMap { "URL" == $0.name ? $0.substructure : nil }

        let allViolations: [RawLintViolation] = urlDeclarations.flatMap { urlInit -> [RawLintViolation] in
            var declarationViolations: [RawLintViolation] = []
            
            guard
                let callArgumentDict = extractSafeURLArgumentFromValidSubstructure(urlInit),
                let bodyByteRange: ByteRange = callArgumentDict.bodyByteRange,
                let location = XcodeIssueLocation.sourceKittenFile(skFile, filePath: scanInfo.filePath, byteRange: bodyByteRange),
                let text = skFile.stringView.substringWithByteRange(bodyByteRange)
            else {
                return declarationViolations
            }

            unvalidSafeInputRegexes.forEach {
                if text.range(of: $0.rule, options: .regularExpression) != nil {
                    declarationViolations.append((
                        location: location,
                        ruleDescription: "String parameter has features that are not compatible with this URL initializer"
                    ))
                }
            }

            if declarationViolations.isEmpty {
                let textWithoutOuterQuotes = text.trimmingCharacters(in: quotesAsCharSet)
                if URL(string: textWithoutOuterQuotes) == nil {
                    declarationViolations.append((
                        location: location,
                        ruleDescription: nil
                    ))
                }
            }
            
            return declarationViolations
        }
        
        let reportResult = XcodeIssue.report(
            allViolations.map({ location, message in
                XcodeIssue.issue(
                    scanInfo.scanMode,
                    message ?? "URL is not valid",
                    at: location
                )
            })
        )
        
        return reportResult
    }
}
