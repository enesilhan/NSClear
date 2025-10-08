import Foundation

/// Risk seviyelerine göre detaylı açıklamalar ve öneriler
struct RiskDescriptor {
    
    /// Risk seviyesine göre detaylı açıklama oluştur
    static func generateDetailedReason(
        for declaration: Declaration,
        riskScore: Int,
        useFastMode: Bool,
        references: [Reference]
    ) -> String {
        var reasons: [String] = []
        
        // 1. Temel durum açıklaması
        reasons.append(generateBasicReason(for: declaration, useFastMode: useFastMode))
        
        // 2. Referans durumu
        if references.isEmpty {
            reasons.append("❌ Hiçbir yerden referans edilmiyor")
        } else {
            reasons.append("⚠️  \(references.count) referans var ama entry point'ten erişilemiyor")
        }
        
        // 3. Özel durumlar
        if declaration.hasProtectedAttributes() {
            reasons.append("🛡️ Korumalı attribute içeriyor - manuel kontrol gerekli")
        }
        
        if declaration.accessLevel == .public || declaration.accessLevel == .open {
            reasons.append("🌐 Public API - harici kullanım olabilir")
        }
        
        return reasons.joined(separator: " | ")
    }
    
    /// Risk seviyesine göre önerilen aksiyon
    static func suggestedAction(for riskScore: Int, declaration: Declaration) -> String {
        let riskLevel = getRiskLevel(for: riskScore)
        
        switch riskLevel {
        case .low:
            return generateLowRiskAction(for: declaration)
        case .medium:
            return generateMediumRiskAction(for: declaration)
        case .high:
            return generateHighRiskAction(for: declaration)
        case .veryHigh:
            return generateVeryHighRiskAction(for: declaration)
        }
    }
    
    /// Detaylı risk açıklaması (kullanıcıya gösterilecek)
    static func detailedExplanation(for riskScore: Int, declaration: Declaration) -> String {
        let riskLevel = getRiskLevel(for: riskScore)
        
        var explanation = ""
        
        // Risk seviyesi açıklaması
        explanation += "📊 **Risk Seviyesi: \(riskLevel.rawValue)** (\(riskScore)/100)\n\n"
        
        // Ne olduğu
        explanation += "**Bu nedir?**\n"
        explanation += "• \(declaration.kind.displayName): `\(declaration.name)`\n"
        explanation += "• Erişim: \(declaration.accessLevel.rawValue)\n"
        explanation += "• Konum: \(declaration.filePath):\(declaration.line)\n\n"
        
        // Neden bulundu
        explanation += "**Neden bulundu?**\n"
        explanation += explainWhyFound(declaration: declaration, riskLevel: riskLevel)
        explanation += "\n"
        
        // Ne yapmalı
        explanation += "**Ne yapmalısınız?**\n"
        explanation += explainWhatToDo(riskLevel: riskLevel, declaration: declaration)
        
        return explanation
    }
    
    // MARK: - Private Helpers
    
    private static func generateBasicReason(for declaration: Declaration, useFastMode: Bool) -> String {
        if useFastMode {
            return "🔍 Entry point değil (fast mode - basit analiz)"
        } else {
            return "🔍 Reachability analizi: Entry point'lerden erişilemiyor"
        }
    }
    
    private static func getRiskLevel(for score: Int) -> RiskLevel {
        switch score {
        case 0..<20: return .low
        case 20..<50: return .medium
        case 50..<80: return .high
        default: return .veryHigh
        }
    }
    
    private static func generateLowRiskAction(for declaration: Declaration) -> String {
        """
        ✅ GÜVENLİ: Bu kodu silebilirsiniz
        
        Önerilen adımlar:
        1. Kodu silin veya yorum satırına alın
        2. Projeyi build edin
        3. Testleri çalıştırın
        4. Sorun yoksa commit edin
        
        Bu declaration private/internal ve hiçbir özel attribute içermiyor.
        Silmesi güvenli görünüyor.
        """
    }
    
    private static func generateMediumRiskAction(for declaration: Declaration) -> String {
        var action = "⚠️  KONTROL GEREKLİ: Silmeden önce kontrol edin\n\n"
        action += "Önerilen adımlar:\n"
        action += "1. Kod içeriğini inceleyin\n"
        action += "2. Gerçekten kullanılmadığından emin olun\n"
        
        if declaration.accessLevel == .internal {
            action += "3. Internal erişim - modül içi kullanım olabilir\n"
        }
        
        action += "4. Kodu yorum satırına alın (silmeyin)\n"
        action += "5. Build + test çalıştırın\n"
        action += "6. Birkaç gün sonra sorun yoksa silin\n\n"
        action += "Bu declaration orta risk seviyesinde. Manuel doğrulama önerilir."
        
        return action
    }
    
    private static func generateHighRiskAction(for declaration: Declaration) -> String {
        var action = "🔶 YÜKSEK RİSK: Dikkatli olun!\n\n"
        
        if declaration.accessLevel == .public || declaration.accessLevel == .open {
            action += "⚠️  Bu bir PUBLIC API!\n"
            action += "• Harici modüller/framework'ler kullanıyor olabilir\n"
            action += "• API breaking change olabilir\n\n"
        }
        
        if declaration.isProtocolRequirement || declaration.isProtocolWitness {
            action += "⚠️  Protocol requirement/witness!\n"
            action += "• Protocol conformance için gerekli olabilir\n\n"
        }
        
        action += "Önerilen adımlar:\n"
        action += "1. ⛔ SAKLA SİLMEYİN\n"
        action += "2. Kod sahibi ile konuşun\n"
        action += "3. Deprecation warning ekleyin\n"
        action += "4. Dokümantasyon kontrol edin\n"
        action += "5. Git history'de kullanım araştırın\n"
        action += "6. En az 1 sprint bekleyin\n\n"
        action += "Bu declaration kritik olabilir. Acele etmeyin!"
        
        return action
    }
    
    private static func generateVeryHighRiskAction(for declaration: Declaration) -> String {
        var action = "🔴 ÇOK YÜKSEK RİSK: SİLMEYİN!\n\n"
        
        if declaration.attributes.contains(where: { $0.contains("@objc") }) {
            action += "⛔ @objc attribute mevcut!\n"
            action += "• Objective-C runtime'dan erişiliyor olabilir\n"
            action += "• Selector-based çağrılar olabilir\n\n"
        }
        
        if declaration.modifiers.contains("dynamic") {
            action += "⛔ dynamic modifier mevcut!\n"
            action += "• Method swizzling kullanılıyor olabilir\n"
            action += "• KVO (Key-Value Observing) olabilir\n\n"
        }
        
        if declaration.attributes.contains(where: { $0.contains("@IBAction") || $0.contains("@IBOutlet") }) {
            action += "⛔ Interface Builder bağlantısı!\n"
            action += "• Storyboard/XIB'den referans var\n"
            action += "• Silmeniz UI'ı bozar\n\n"
        }
        
        action += "YAPILMASI GEREKENLER:\n"
        action += "1. ❌ ASLA SİLMEYİN\n"
        action += "2. Bu declaration sistem tarafından kullanılıyor\n"
        action += "3. Static analiz ile tespit edilemez\n"
        action += "4. Runtime'da kullanılıyor olabilir\n"
        action += "5. Silmeniz uygulamanızı çökertir\n\n"
        action += "⚠️  Bu bulgu muhtemelen FALSE POSITIVE!"
        
        return action
    }
    
    private static func explainWhyFound(declaration: Declaration, riskLevel: RiskLevel) -> String {
        var explanation = ""
        
        switch riskLevel {
        case .low:
            explanation += "• Private/internal erişim seviyesinde\n"
            explanation += "• Hiçbir özel attribute/modifier yok\n"
            explanation += "• Entry point değil\n"
            explanation += "• Basit helper fonksiyon/property gibi görünüyor"
            
        case .medium:
            explanation += "• Internal/fileprivate erişim seviyesinde\n"
            explanation += "• Modül içinden erişilebilir\n"
            explanation += "• Static analiz ile kullanım tespit edilemedi\n"
            explanation += "• String-based veya indirect kullanım olabilir"
            
        case .high:
            explanation += "• Public/open erişim seviyesinde\n"
            explanation += "• Harici modüllerden erişilebilir\n"
            explanation += "• API'nin parçası olabilir\n"
            explanation += "• Kaldırmanız breaking change olabilir"
            
        case .veryHigh:
            explanation += "• Özel attribute/modifier içeriyor (@objc, dynamic, @IB*, vb.)\n"
            explanation += "• Runtime'da dinamik olarak erişilir\n"
            explanation += "• Objective-C interop veya IB bağlantısı var\n"
            explanation += "• Static analiz ile kullanım tespit edilemez"
        }
        
        return explanation
    }
    
    private static func explainWhatToDo(riskLevel: RiskLevel, declaration: Declaration) -> String {
        var explanation = ""
        
        switch riskLevel {
        case .low:
            explanation += "✅ **Güvenle silebilirsiniz:**\n\n"
            explanation += "1. Kodu silin\n"
            explanation += "2. Build edin (⌘+B)\n"
            explanation += "3. Testleri çalıştırın (⌘+U)\n"
            explanation += "4. Sorun yoksa commit edin\n\n"
            explanation += "💡 İpucu: Önce yorum satırına alıp test edebilirsiniz."
            
        case .medium:
            explanation += "⚠️  **Dikkatli olun:**\n\n"
            explanation += "1. Kodu inceleyin - ne yaptığını anlayın\n"
            explanation += "2. Project-wide search yapın (⇧⌘F)\n"
            explanation += "3. String literal'larda kullanılıyor mu bakın\n"
            explanation += "4. Yorum satırına alın (silmeyin)\n"
            explanation += "5. Tüm testleri çalıştırın\n"
            explanation += "6. Manuel test yapın\n"
            explanation += "7. 1-2 sprint bekleyin\n"
            explanation += "8. Sorun yoksa silin\n\n"
            explanation += "💡 İpucu: Git blame ile kod tarihçesine bakın."
            
        case .high:
            explanation += "🔶 **Çok dikkatli olun:**\n\n"
            explanation += "1. ⛔ Silmeyin - işaretleyin\n"
            explanation += "2. Deprecation warning ekleyin\n"
            if declaration.kind == .function || declaration.kind == .method {
                explanation += "   @available(*, deprecated, message: \"Use X instead\")\n"
            }
            explanation += "3. Release notes'a ekleyin\n"
            explanation += "4. Tüm consumer'ları bulun\n"
            explanation += "5. Migration guide yazın\n"
            explanation += "6. En az 2 major version bekleyin\n\n"
            explanation += "💡 İpucu: Semantic versioning kurallarına uyun."
            
        case .veryHigh:
            explanation += "🔴 **ASLA SİLMEYİN:**\n\n"
            explanation += "1. ❌ Bu kodu silmeyin!\n"
            explanation += "2. Runtime'da kullanılıyor olabilir\n"
            explanation += "3. Static analiz yeterli değil\n"
            explanation += "4. False positive olması muhtemel\n\n"
            
            if declaration.attributes.contains(where: { $0.contains("@objc") }) {
                explanation += "**@objc neden önemli?**\n"
                explanation += "• Objective-C kodu bu Swift kodunu çağırabilir\n"
                explanation += "• Selector-based çağrılar (#selector) kullanılabilir\n"
                explanation += "• NSNotification, KVO kullanımı olabilir\n\n"
            }
            
            if declaration.attributes.contains(where: { $0.contains("@IB") }) {
                explanation += "**Interface Builder bağlantısı:**\n"
                explanation += "• Storyboard/XIB dosyasında kullanılıyor\n"
                explanation += "• Silmeniz runtime crash'e sebep olur\n"
                explanation += "• IB bağlantılarını kontrol edin\n\n"
            }
            
            explanation += "💡 İpucu: Bu bulguyu yoksayın (ignore)."
        }
        
        return explanation
    }
}

