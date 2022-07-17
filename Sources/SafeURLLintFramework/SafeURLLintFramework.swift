import Foundation
import SourceKittenFramework

private let quotesAsCharSet = CharacterSet(arrayLiteral: "\"")
private let expectedParameterName = "safeString"
private let unvalidSafeInputRegexes = [
    (rule: #".+(?<!\\)\".+"#, description: "Non-escaped string delimiter mid-string"),
    (rule: #".+(?<!\\)\\\(.+"#, description: "Interpolation")
    ]
private let pattern = "URL\\s*\\(\\s*\(expectedParameterName)\\s*:\\s*\""

private let disablerComment = "//\\s*safeurl:disable"
private let warnModeComment = "//\\s*safeurl:warn"

typealias SourceKittenSubstructure = [SourceKittenDictionary]

public class SafeURLScanInfo {
    let filePath: String
    let fileContent: String
    let scanMode: EditorMessageType
    
    init(filePath: String, fileContent: String, scanMode: EditorMessageType) {
        self.filePath = filePath
        self.fileContent = fileContent
        self.scanMode = scanMode
    }
}

public class SafeURLKit {
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
    
    public static func scanAndReport(_ scanInfo: SafeURLScanInfo) throws -> Bool {
        let skFile = SourceKittenFramework.File(contents: scanInfo.fileContent)
        let skStructure = try SourceKittenFramework.Structure(file: skFile)
        let skd = SourceKittenDictionary(skStructure.dictionary)

        let urlDeclarations: [SourceKittenSubstructure] = skd.flatten().compactMap { "URL" == $0.name ? $0.substructure : nil }

        var presentedErrors = false

        urlDeclarations.forEach { urlInit in
            guard let callArgumentDict = extractSafeURLArgumentFromValidSubstructure(urlInit),
                let bodyByteRange = callArgumentDict.bodyByteRange,
                let location = Location(file: skFile, filePath: scanInfo.filePath, byteRange: bodyByteRange),
                let text = skFile.stringView.substringWithByteRange(bodyByteRange)
                else
            {
                return
            }

            var violations: [(location: Location, ruleDescription: String?)] = []

            unvalidSafeInputRegexes.forEach {
                if text.range(of: $0.rule, options: .regularExpression) != nil {
                    violations.append((
                        location: location,
                        ruleDescription: $0.description
                    ))
                }
            }

            if violations.isEmpty {
                let textWithoutOuterQuotes = text.trimmingCharacters(in: quotesAsCharSet)
                if URL(string: textWithoutOuterQuotes) == nil {
                    violations.append((
                        location: location,
                        ruleDescription: nil
                    ))
                }
            }

            violations.forEach { violation in
                if case .error = scanInfo.scanMode {
                    presentedErrors = true
                }
                reportMessageToEditor(
                    location: violation.location,
                    type: scanInfo.scanMode,
                    description: "URL syntax error" + (violation.ruleDescription.map { ": \($0)" } ?? "")
                )
            }
        }

        return presentedErrors
    }
}
