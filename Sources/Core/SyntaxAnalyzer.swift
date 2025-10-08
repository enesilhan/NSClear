import Foundation
import SwiftSyntax
import SwiftParser

/// SwiftSyntax kullanarak Swift kaynak kodunu analiz eden sınıf
final class SyntaxAnalyzer {
    private let config: NSClearConfig
    
    init(config: NSClearConfig = NSClearConfig()) {
        self.config = config
    }
    
    /// Dosyadaki tüm declaration'ları topla
    func analyzeFile(at path: String) throws -> [Declaration] {
        let url = URL(fileURLWithPath: path)
        let source = try String(contentsOf: url, encoding: .utf8)
        
        let sourceFile = Parser.parse(source: source)
        let visitor = DeclarationVisitor(filePath: path, sourceText: source)
        visitor.walk(sourceFile)
        
        return visitor.declarations
    }
    
    /// Birden fazla dosyayı analiz et
    func analyzeFiles(at paths: [String]) async throws -> [Declaration] {
        var allDeclarations: [Declaration] = []
        
        for path in paths {
            // Hariç tutulacak dosyaları atla
            if shouldExclude(path) {
                continue
            }
            
            do {
                let declarations = try analyzeFile(at: path)
                allDeclarations.append(contentsOf: declarations)
            } catch {
                print("⚠️  Dosya analiz edilemedi: \(path) - \(error.localizedDescription)")
            }
        }
        
        return allDeclarations
    }
    
    private func shouldExclude(_ path: String) -> Bool {
        for pattern in config.exclude {
            if path.matches(glob: pattern) {
                return true
            }
        }
        return false
    }
}

/// Declaration'ları toplayan SyntaxVisitor
private final class DeclarationVisitor: SyntaxVisitor {
    let filePath: String
    let sourceText: String
    var declarations: [Declaration] = []
    private var currentContext: [String] = [] // Parent context stack
    
    init(filePath: String, sourceText: String) {
        self.filePath = filePath
        self.sourceText = sourceText
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let decl = createDeclaration(
            kind: .class,
            name: node.name.text,
            node: Syntax(node),
            accessLevel: extractAccessLevel(from: node.modifiers),
            attributes: extractAttributes(from: node.attributes),
            modifiers: extractModifiers(from: node.modifiers)
        )
        declarations.append(decl)
        
        currentContext.append(node.name.text)
        defer { currentContext.removeLast() }
        
        return .visitChildren
    }
    
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let decl = createDeclaration(
            kind: .struct,
            name: node.name.text,
            node: Syntax(node),
            accessLevel: extractAccessLevel(from: node.modifiers),
            attributes: extractAttributes(from: node.attributes),
            modifiers: extractModifiers(from: node.modifiers)
        )
        declarations.append(decl)
        
        currentContext.append(node.name.text)
        defer { currentContext.removeLast() }
        
        return .visitChildren
    }
    
    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        let decl = createDeclaration(
            kind: .enum,
            name: node.name.text,
            node: Syntax(node),
            accessLevel: extractAccessLevel(from: node.modifiers),
            attributes: extractAttributes(from: node.attributes),
            modifiers: extractModifiers(from: node.modifiers)
        )
        declarations.append(decl)
        
        currentContext.append(node.name.text)
        defer { currentContext.removeLast() }
        
        return .visitChildren
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let decl = createDeclaration(
            kind: .protocol,
            name: node.name.text,
            node: Syntax(node),
            accessLevel: extractAccessLevel(from: node.modifiers),
            attributes: extractAttributes(from: node.attributes),
            modifiers: extractModifiers(from: node.modifiers)
        )
        declarations.append(decl)
        
        currentContext.append(node.name.text)
        defer { currentContext.removeLast() }
        
        return .visitChildren
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeName = node.extendedType.description.trimmingCharacters(in: .whitespaces)
        let decl = createDeclaration(
            kind: .extension,
            name: "extension \(typeName)",
            node: Syntax(node),
            accessLevel: extractAccessLevel(from: node.modifiers),
            attributes: extractAttributes(from: node.attributes),
            modifiers: extractModifiers(from: node.modifiers)
        )
        declarations.append(decl)
        
        currentContext.append("extension \(typeName)")
        defer { currentContext.removeLast() }
        
        return .visitChildren
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let kind: DeclarationKind = currentContext.isEmpty ? .function : .method
        let decl = createDeclaration(
            kind: kind,
            name: node.name.text,
            node: Syntax(node),
            accessLevel: extractAccessLevel(from: node.modifiers),
            attributes: extractAttributes(from: node.attributes),
            modifiers: extractModifiers(from: node.modifiers),
            parentDeclaration: currentContext.last
        )
        declarations.append(decl)
        
        return .skipChildren
    }
    
    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = "init" + (node.optionalMark != nil ? "?" : "")
        let decl = createDeclaration(
            kind: .initializer,
            name: name,
            node: Syntax(node),
            accessLevel: extractAccessLevel(from: node.modifiers),
            attributes: extractAttributes(from: node.attributes),
            modifiers: extractModifiers(from: node.modifiers),
            parentDeclaration: currentContext.last
        )
        declarations.append(decl)
        
        return .skipChildren
    }
    
    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let kind: DeclarationKind = node.bindingSpecifier.tokenKind == .keyword(.let) ? .constant : .property
        
        // Her bir binding için ayrı declaration oluştur
        for binding in node.bindings {
            if let pattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                let decl = createDeclaration(
                    kind: kind,
                    name: pattern.identifier.text,
                    node: Syntax(node),
                    accessLevel: extractAccessLevel(from: node.modifiers),
                    attributes: extractAttributes(from: node.attributes),
                    modifiers: extractModifiers(from: node.modifiers),
                    parentDeclaration: currentContext.last
                )
                declarations.append(decl)
            }
        }
        
        return .skipChildren
    }
    
    override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        let decl = createDeclaration(
            kind: .typealias,
            name: node.name.text,
            node: Syntax(node),
            accessLevel: extractAccessLevel(from: node.modifiers),
            attributes: extractAttributes(from: node.attributes),
            modifiers: extractModifiers(from: node.modifiers),
            parentDeclaration: currentContext.last
        )
        declarations.append(decl)
        
        return .skipChildren
    }
    
    override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
        let decl = createDeclaration(
            kind: .subscript,
            name: "subscript",
            node: Syntax(node),
            accessLevel: extractAccessLevel(from: node.modifiers),
            attributes: extractAttributes(from: node.attributes),
            modifiers: extractModifiers(from: node.modifiers),
            parentDeclaration: currentContext.last
        )
        declarations.append(decl)
        
        return .skipChildren
    }
    
    // MARK: - Helper Methods
    
    private func createDeclaration(
        kind: DeclarationKind,
        name: String,
        node: Syntax,
        accessLevel: AccessLevel,
        attributes: [String],
        modifiers: [String],
        parentDeclaration: String? = nil
    ) -> Declaration {
        let position = node.position
        let length = node.totalLength
        
        // SourceLocation hesapla
        let converter = SourceLocationConverter(fileName: filePath, tree: node.root)
        let location = converter.location(for: position)
        
        return Declaration(
            kind: kind,
            name: name,
            filePath: filePath,
            line: location.line,
            column: location.column,
            byteOffset: position.utf8Offset,
            byteLength: length.utf8Length,
            accessLevel: accessLevel,
            attributes: attributes,
            modifiers: modifiers,
            isProtocolRequirement: false, // Bu IndexStore'dan belirlenir
            isProtocolWitness: false,     // Bu IndexStore'dan belirlenir
            parentDeclaration: parentDeclaration
        )
    }
    
    private func extractAccessLevel(from modifiers: DeclModifierListSyntax?) -> AccessLevel {
        guard let modifiers = modifiers else { return .internal }
        
        for modifier in modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.private):
                return .private
            case .keyword(.fileprivate):
                return .fileprivate
            case .keyword(.internal):
                return .internal
            case .keyword(.public):
                return .public
            case .keyword(.open):
                return .open
            default:
                continue
            }
        }
        
        return .internal
    }
    
    private func extractAttributes(from attributes: AttributeListSyntax?) -> [String] {
        guard let attributes = attributes else { return [] }
        
        return attributes.compactMap { element in
            if let attribute = element.as(AttributeSyntax.self) {
                return "@\(attribute.attributeName.description.trimmingCharacters(in: .whitespaces))"
            }
            return nil
        }
    }
    
    private func extractModifiers(from modifiers: DeclModifierListSyntax?) -> [String] {
        guard let modifiers = modifiers else { return [] }
        
        return modifiers.map { modifier in
            modifier.name.text
        }
    }
}

// MARK: - String Extension for Glob Matching

extension String {
    func matches(glob pattern: String) -> Bool {
        // Basit glob pattern matching
        let regexPattern = pattern
            .replacingOccurrences(of: "**", with: "DOUBLE_STAR")
            .replacingOccurrences(of: "*", with: "[^/]*")
            .replacingOccurrences(of: "DOUBLE_STAR", with: ".*")
            .replacingOccurrences(of: "?", with: ".")
        
        do {
            let regex = try NSRegularExpression(pattern: "^\(regexPattern)$", options: [])
            let range = NSRange(location: 0, length: self.utf16.count)
            return regex.firstMatch(in: self, options: [], range: range) != nil
        } catch {
            return false
        }
    }
}

