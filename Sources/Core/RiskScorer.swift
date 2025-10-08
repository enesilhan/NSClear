import Foundation

/// Risk skorlama motoru
struct RiskScorer {
    let config: RiskScoringConfig
    
    init(config: RiskScoringConfig = RiskScoringConfig()) {
        self.config = config
    }
    
    /// Declaration için risk skoru hesapla
    func calculateRiskScore(for declaration: Declaration, references: [Reference]) -> Int {
        var score = 0
        
        // Access level bazlı risk
        score += accessLevelRisk(declaration.accessLevel)
        
        // Attribute bazlı risk
        score += attributeRisk(declaration.attributes)
        
        // Modifier bazlı risk
        score += modifierRisk(declaration.modifiers)
        
        // Protocol/witness riski
        if declaration.isProtocolRequirement || declaration.isProtocolWitness {
            score += config.protocolWitnessWeight
        }
        
        // Test-only riski
        if isTestOnly(declaration) {
            score += config.testOnlyWeight
        }
        
        // Private helper (düşük risk)
        if declaration.accessLevel == .private && isSimpleHelper(declaration) {
            score = min(score, config.privateHelperWeight)
        }
        
        // Referans sayısına göre ayarlama (referans varsa risk düşer)
        if !references.isEmpty {
            score = Int(Double(score) * 0.5)
        }
        
        return min(max(score, 0), 100)
    }
    
    private func accessLevelRisk(_ accessLevel: AccessLevel) -> Int {
        switch accessLevel {
        case .private:
            return 5
        case .fileprivate:
            return 10
        case .internal:
            return 20
        case .public:
            return config.publicAPIWeight
        case .open:
            return config.publicAPIWeight + 5
        }
    }
    
    private func attributeRisk(_ attributes: [String]) -> Int {
        var risk = 0
        
        // ObjC/dynamic attributeleri
        if attributes.contains(where: { $0.contains("@objc") || $0.contains("@_objc") }) {
            risk = max(risk, config.objcDynamicWeight)
        }
        
        // IB attributeleri
        if attributes.contains(where: { $0.contains("@IBAction") || $0.contains("@IBOutlet") }) {
            risk = max(risk, config.selectorPresenceWeight)
        }
        
        // Inlinable/usableFromInline
        if attributes.contains(where: { $0.contains("@inlinable") || $0.contains("@usableFromInline") }) {
            risk = max(risk, config.publicAPIWeight)
        }
        
        // Entry point attributeleri
        if attributes.contains(where: { $0.contains("@main") || $0.contains("@UIApplicationMain") || $0.contains("@NSApplicationMain") }) {
            risk = 100 // Kesinlikle silinmemeli
        }
        
        return risk
    }
    
    private func modifierRisk(_ modifiers: [String]) -> Int {
        if modifiers.contains("dynamic") {
            return config.objcDynamicWeight
        }
        return 0
    }
    
    private func isTestOnly(_ declaration: Declaration) -> Bool {
        // Test dosyasında mı?
        let path = declaration.filePath.lowercased()
        if path.contains("test") {
            return true
        }
        
        // Test attribute'u var mı?
        if declaration.attributes.contains(where: { $0.contains("@Test") || $0.contains("@testable") }) {
            return true
        }
        
        return false
    }
    
    private func isSimpleHelper(_ declaration: Declaration) -> Bool {
        // Basit helper: private, tek satırlık, küçük boyutlu
        guard declaration.accessLevel == .private else { return false }
        
        // Function veya computed property olmalı
        guard declaration.kind == .function || declaration.kind == .method || declaration.kind == .property else {
            return false
        }
        
        // Byte uzunluğu küçük olmalı (< 200 bytes)
        return declaration.byteLength < 200
    }
}

/// Risk seviyesi açıklama metinleri
extension RiskLevel {
    var description: String {
        switch self {
        case .low:
            return "Düşük risk: Bu declaration'ın silinmesi güvenli görünüyor."
        case .medium:
            return "Orta risk: Manuel kontrol önerilir."
        case .high:
            return "Yüksek risk: Public API veya özel attribute içeriyor."
        case .veryHigh:
            return "Çok yüksek risk: ObjC/dynamic veya kritik entry point."
        }
    }
}

