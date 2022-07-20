import SourceKittenFramework

/// A collection of keys and values as parsed out of SourceKit, with many conveniences for accessing SwiftLint-specific
/// values.
struct SourceKittenDictionary {
    /// The underlying SourceKitten dictionary.
    let value: [String: SourceKitRepresentable]
    /// The cached substructure for this dictionary. Empty if there is no substructure.
    let substructure: [SourceKittenDictionary]

    /// The kind of Swift expression represented by this dictionary, if it is an expression.
    let expressionKind: SwiftExpressionKind?
    /// The kind of Swift declaration represented by this dictionary, if it is a declaration.
    let declarationKind: SwiftDeclarationKind?
    /// The kind of Swift statement represented by this dictionary, if it is a statement.
    let statementKind: StatementKind?

    /// Creates a SourceKitten dictionary given a `Dictionary<String, SourceKitRepresentable>` input.
    ///
    /// - parameter value: The input dictionary/
    init(_ value: [String: SourceKitRepresentable]) {
        self.value = value

        let substructure = value["key.substructure"] as? [SourceKitRepresentable] ?? []
        self.substructure = substructure.compactMap { $0 as? [String: SourceKitRepresentable] }
            .map(SourceKittenDictionary.init)

        let stringKind = value["key.kind"] as? String
        self.expressionKind = stringKind.flatMap(SwiftExpressionKind.init)
        self.declarationKind = stringKind.flatMap(SwiftDeclarationKind.init)
        self.statementKind = stringKind.flatMap(StatementKind.init)
    }

    /// Body length
    var bodyLength: ByteCount? {
        return (value["key.bodylength"] as? Int64).map(ByteCount.init)
    }

    /// Body offset.
    var bodyOffset: ByteCount? {
        return (value["key.bodyoffset"] as? Int64).map(ByteCount.init)
    }

    /// Body byte range.
    var bodyByteRange: ByteRange? {
        guard let offset = bodyOffset, let length = bodyLength else { return nil }
        return ByteRange(location: offset, length: length)
    }

    /// Kind.
    var kind: String? {
        return value["key.kind"] as? String
    }

    /// Length.
    var length: ByteCount? {
        return (value["key.length"] as? Int64).map(ByteCount.init)
    }
    /// Name.
    var name: String? {
        return value["key.name"] as? String
    }

    /// Name length.
    var nameLength: ByteCount? {
        return (value["key.namelength"] as? Int64).map(ByteCount.init)
    }

    /// Name offset.
    var nameOffset: ByteCount? {
        return (value["key.nameoffset"] as? Int64).map(ByteCount.init)
    }

    /// Byte range of name.
    var nameByteRange: ByteRange? {
        guard let offset = nameOffset, let length = nameLength else { return nil }
        return ByteRange(location: offset, length: length)
    }

    /// Offset.
    var offset: ByteCount? {
        return (value["key.offset"] as? Int64).map(ByteCount.init)
    }

    /// Returns byte range starting from `offset` with `length` bytes
    var byteRange: ByteRange? {
        guard let offset = offset, let length = length else { return nil }
        return ByteRange(location: offset, length: length)
    }

    /// Setter accessibility.
    var setterAccessibility: String? {
        return value["key.setter_accessibility"] as? String
    }

    /// Type name.
    var typeName: String? {
        return value["key.typename"] as? String
    }

    /// Documentation offset.
    var docOffset: ByteCount? {
        return (value["key.docoffset"] as? Int64).flatMap(ByteCount.init)
    }

    /// Documentation length.
    var docLength: ByteCount? {
        return (value["key.doclength"] as? Int64).flatMap(ByteCount.init)
    }

    /// The attribute for this dictionary, as returned by SourceKit.
    var attribute: String? {
        return value["key.attribute"] as? String
    }

    /// Module name in `@import` expressions.
    var moduleName: String? {
        return value["key.modulename"] as? String
    }

    /// The line number for this declaration.
    var line: Int64? {
        return value["key.line"] as? Int64
    }

    /// The column number for this declaration.
    var column: Int64? {
        return value["key.column"] as? Int64
    }

    /// The `SwiftDeclarationAttributeKind` values associated with this dictionary.
    var enclosedSwiftAttributes: [SwiftDeclarationAttributeKind] {
        return swiftAttributes.compactMap { $0.attribute }
            .compactMap(SwiftDeclarationAttributeKind.init(rawValue:))
    }

    /// The fully preserved SourceKitten dictionaries for all the attributes associated with this dictionary.
    var swiftAttributes: [SourceKittenDictionary] {
        let array = value["key.attributes"] as? [SourceKitRepresentable] ?? []
        let dictionaries = array.compactMap { $0 as? [String: SourceKitRepresentable] }
            .map(SourceKittenDictionary.init)
        return dictionaries
    }

    var elements: [SourceKittenDictionary] {
        let elements = value["key.elements"] as? [SourceKitRepresentable] ?? []
        return elements.compactMap { $0 as? [String: SourceKitRepresentable] }
        .map(SourceKittenDictionary.init)
    }

    var entities: [SourceKittenDictionary] {
        let entities = value["key.entities"] as? [SourceKitRepresentable] ?? []
        return entities.compactMap { $0 as? [String: SourceKitRepresentable] }
            .map(SourceKittenDictionary.init)
    }

    var enclosedVarParameters: [SourceKittenDictionary] {
        return substructure.flatMap { subDict -> [SourceKittenDictionary] in
            if subDict.declarationKind == .varParameter {
                return [subDict]
            } else if subDict.expressionKind == .argument ||
                subDict.expressionKind == .closure {
                return subDict.enclosedVarParameters
            }

            return []
        }
    }

    var enclosedArguments: [SourceKittenDictionary] {
        return substructure.flatMap { subDict -> [SourceKittenDictionary] in
            guard subDict.expressionKind == .argument else {
                return []
            }

            return [subDict]
        }
    }

    var inheritedTypes: [String] {
        let array = value["key.inheritedtypes"] as? [SourceKitRepresentable] ?? []
        return array.compactMap { ($0 as? [String: String]).flatMap { $0["key.name"] } }
    }
}

extension SourceKittenDictionary {
    func flatten() -> [SourceKittenDictionary] {
        var arr = substructure.flatMap {
            $0.flatten()
        }
        arr.append(self)
        return arr
    }
}

extension SourceKittenFramework.Structure {
    func readableDictionary() -> SourceKittenDictionary {
        SourceKittenDictionary(self.dictionary)
    }
}
