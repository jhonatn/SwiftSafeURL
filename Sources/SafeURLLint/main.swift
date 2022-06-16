import Foundation
import SourceKittenFramework

private let quotesAsCharSet = CharacterSet(arrayLiteral: "\"")
private let expectedParameterName = "safeString"
private let unvalidSafeInputRegexes = [
    (rule: #".+(?<!\\)\".+"#, description: "Non-escaped string delimiter mid-string"),
    (rule: #".+(?<!\\)\\\(.+"#, description: "Interpolation")
    ]

// MARK: Start scan

let args = ProcessInfo().arguments

guard args.count > 1, let skFile = SourceKittenFramework.File(path: args[1]) else {
    exit(1)
}

//let skStructure = try SourceKittenFramework.Structure(file: skFile)
let contents = skFile.contents
let newFile = File(contents: contents)
let skEditorOpenRequest = Request.editorOpen(file: newFile)
let skEditorOpenResponse = try skEditorOpenRequest.send()
let skStructure = SourceKittenFramework.Structure(sourceKitResponse: skEditorOpenResponse)
let skd = SourceKittenDictionary(skStructure.dictionary)

let urlDeclarations = skd.flatten().compactMap { "URL" == $0.name ? $0.substructure : nil }
let urlSafeStringAttributes = urlDeclarations.compactMap { declarationItems -> SourceKittenDictionary? in
    declarationItems.first {
        $0.expressionKind == .argument && $0.name == expectedParameterName
    }
}

urlSafeStringAttributes.forEach { dict in
    guard let bodyByteRange = dict.bodyByteRange,
        let location = Location(file: skFile, byteRange: bodyByteRange),
        let text = skFile.stringView.substringWithByteRange(bodyByteRange)
        else
    {
        print("Can't find argument value")
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
                ruleDescription: "Invalid URL"
            ))
        }
    }

    violations.forEach { violation in
        reportMessageToEditor(
            location: violation.location,
            description: "URL syntax error" + (violation.ruleDescription.map { ": \($0)" } ?? "")
        )
    }
}
