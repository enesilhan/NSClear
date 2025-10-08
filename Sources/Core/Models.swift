import Foundation

/// Swift declaration türleri
enum DeclarationKind: String, Codable, CaseIterable {
    case `class`
    case `struct`
    case `enum`
    case `protocol`
    case `extension`
    case function
    case method
    case initializer
    case property
    case variable
    case constant
    case `typealias`
    case `subscript`
    case `operator`
    case precedenceGroup
    case `associatedtype`
    
    var displayName: String {
        switch self {
        case .class: return "Class"
        case .struct: return "Struct"
        case .enum: return "Enum"
        case .protocol: return "Protocol"
        case .extension: return "Extension"
        case .function: return "Function"
        case .method: return "Method"
        case .initializer: return "Initializer"
        case .property: return "Property"
        case .variable: return "Variable"
        case .constant: return "Constant"
        case .typealias: return "Typealias"
        case .subscript: return "Subscript"
        case .operator: return "Operator"
        case .precedenceGroup: return "Precedence Group"
        case .associatedtype: return "Associated Type"
        }
    }
}

/// Access level türleri
enum AccessLevel: String, Codable {
    case `private`
    case `fileprivate`
    case `internal`
    case `public`
    case `open`
    
    var riskMultiplier: Double {
        switch self {
        case .private: return 1.0
        case .fileprivate: return 1.2
        case .internal: return 1.5
        case .public: return 2.0
        case .open: return 2.5
        }
    }
}

/// Swift declaration temsili
struct Declaration: Codable, Identifiable {
    let id: UUID
    let kind: DeclarationKind
    let name: String
    let filePath: String
    let line: Int
    let column: Int
    let byteOffset: Int
    let byteLength: Int
    let accessLevel: AccessLevel
    let attributes: [String]
    let modifiers: [String]
    let isProtocolRequirement: Bool
    let isProtocolWitness: Bool
    let parentDeclaration: String?
    
    init(
        id: UUID = UUID(),
        kind: DeclarationKind,
        name: String,
        filePath: String,
        line: Int,
        column: Int,
        byteOffset: Int,
        byteLength: Int,
        accessLevel: AccessLevel,
        attributes: [String] = [],
        modifiers: [String] = [],
        isProtocolRequirement: Bool = false,
        isProtocolWitness: Bool = false,
        parentDeclaration: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.filePath = filePath
        self.line = line
        self.column = column
        self.byteOffset = byteOffset
        self.byteLength = byteLength
        self.accessLevel = accessLevel
        self.attributes = attributes
        self.modifiers = modifiers
        self.isProtocolRequirement = isProtocolRequirement
        self.isProtocolWitness = isProtocolWitness
        self.parentDeclaration = parentDeclaration
    }
    
    /// Declaration'ın korumalı attributelere sahip olup olmadığını kontrol et
    func hasProtectedAttributes() -> Bool {
        let protectedAttributes = [
            "@objc", "@IBAction", "@IBOutlet", "@NSManaged",
            "@inlinable", "@usableFromInline", "@_cdecl", "@_spi",
            "@main", "@UIApplicationMain", "@NSApplicationMain"
        ]
        return attributes.contains(where: { attr in
            protectedAttributes.contains(where: { attr.contains($0) })
        })
    }
    
    /// Declaration'ın korumalı modifier'lara sahip olup olmadığını kontrol et
    func hasProtectedModifiers() -> Bool {
        return modifiers.contains("dynamic")
    }
}

/// Kullanılmayan kod bulgusu
struct Finding: Codable, Identifiable {
    let id: UUID
    let declaration: Declaration
    let reason: String
    let riskScore: Int
    let references: [Reference]
    let suggestedAction: String
    var isSelected: Bool
    
    init(
        id: UUID = UUID(),
        declaration: Declaration,
        reason: String,
        riskScore: Int,
        references: [Reference] = [],
        suggestedAction: String = "Delete declaration",
        isSelected: Bool = false
    ) {
        self.id = id
        self.declaration = declaration
        self.reason = reason
        self.riskScore = riskScore
        self.references = references
        self.suggestedAction = suggestedAction
        self.isSelected = isSelected
    }
    
    var riskLevel: RiskLevel {
        switch riskScore {
        case 0..<20: return .low
        case 20..<50: return .medium
        case 50..<80: return .high
        default: return .veryHigh
        }
    }
}

/// Risk seviyesi
enum RiskLevel: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case veryHigh = "Very High"
    
    var color: String {
        switch self {
        case .low: return "🟢"
        case .medium: return "🟡"
        case .high: return "🟠"
        case .veryHigh: return "🔴"
        }
    }
}

/// Sembol referansı
struct Reference: Codable {
    let filePath: String
    let line: Int
    let column: Int
    let context: String
    
    init(filePath: String, line: Int, column: Int, context: String) {
        self.filePath = filePath
        self.line = line
        self.column = column
        self.context = context
    }
}

/// Entry point temsili
struct EntryPoint: Codable {
    let declaration: Declaration
    let entryPointKind: EntryPointKind
    
    init(declaration: Declaration, entryPointKind: EntryPointKind) {
        self.declaration = declaration
        self.entryPointKind = entryPointKind
    }
}

/// Entry point türleri
enum EntryPointKind: String, Codable {
    case main
    case swiftUIApp
    case uiApplicationMain
    case publicAPI
    case objcSymbol
    case testEntryPoint
    case customPattern
}

/// Analiz sonucu
struct AnalysisResult: Codable {
    let findings: [Finding]
    let totalDeclarations: Int
    let analyzedFiles: [String]
    let entryPoints: [EntryPoint]
    let analysisDate: Date
    let configUsed: String?
    
    init(
        findings: [Finding],
        totalDeclarations: Int,
        analyzedFiles: [String],
        entryPoints: [EntryPoint],
        analysisDate: Date = Date(),
        configUsed: String? = nil
    ) {
        self.findings = findings
        self.totalDeclarations = totalDeclarations
        self.analyzedFiles = analyzedFiles
        self.entryPoints = entryPoints
        self.analysisDate = analysisDate
        self.configUsed = configUsed
    }
    
    var unusedCount: Int {
        findings.count
    }
    
    var usagePercentage: Double {
        guard totalDeclarations > 0 else { return 0 }
        return Double(totalDeclarations - unusedCount) / Double(totalDeclarations) * 100
    }
}

