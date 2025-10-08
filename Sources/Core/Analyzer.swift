import Foundation

/// Ana analiz orkestratörü - tüm bileşenleri koordine eder
final class Analyzer {
    private let config: NSClearConfig
    private let workingDirectory: String
    private let indexStorePath: String?
    
    init(
        workingDirectory: String,
        indexStorePath: String? = nil,
        config: NSClearConfig = NSClearConfig()
    ) {
        self.workingDirectory = workingDirectory
        self.indexStorePath = indexStorePath
        self.config = config
    }
    
    /// Tam analiz çalıştır
    func analyze() async throws -> AnalysisResult {
        print("🔍 NSClear - Kullanılmayan Kod Analizi Başlıyor...")
        print("")
        
        // 1. Swift dosyalarını bul
        print("📁 Swift dosyaları taranıyor...")
        let swiftFiles = try findSwiftFiles()
        print("   ✓ \(swiftFiles.count) Swift dosyası bulundu")
        
        // 2. Syntax analizi - tüm declaration'ları topla
        print("📝 Syntax analizi yapılıyor...")
        let syntaxAnalyzer = SyntaxAnalyzer(config: config)
        let declarations = try await syntaxAnalyzer.analyzeFiles(at: swiftFiles)
        print("   ✓ \(declarations.count) declaration bulundu")
        
        // 3. IndexStore hazırla
        print("📊 Index store hazırlanıyor...")
        let indexAnalyzer = try IndexStoreAnalyzer(
            indexStorePath: indexStorePath,
            config: config
        )
        print("   ✓ Index store hazır")
        
        // 4. Entry point'leri bul
        print("🎯 Entry point'ler belirleniyor...")
        let entryPoints = indexAnalyzer.findEntryPoints(in: declarations)
        print("   ✓ \(entryPoints.count) entry point bulundu")
        
        // 5. Reachability analizi
        print("🔗 Reachability analizi yapılıyor...")
        let reachabilityAnalyzer = ReachabilityAnalyzer(
            declarations: declarations,
            entryPoints: entryPoints,
            indexAnalyzer: indexAnalyzer
        )
        let unreachable = await reachabilityAnalyzer.analyze()
        print("   ✓ \(unreachable.count) erişilemeyen declaration tespit edildi")
        
        // 6. Risk skorlaması
        print("🎯 Risk skorlaması yapılıyor...")
        let riskScorer = RiskScorer(config: config.riskScoring)
        var findings: [Finding] = []
        
        for declaration in unreachable {
            // Koruma kontrolü
            if reachabilityAnalyzer.requiresProtection(declaration: declaration, config: config.protections) {
                print("   ⚠️  Korunuyor: \(declaration.name) (protected attribute/modifier)")
                continue
            }
            
            // Public API kontrolü
            if !config.checkPublicAPI && 
               (declaration.accessLevel == .public || declaration.accessLevel == .open) {
                continue
            }
            
            // Referansları bul
            let references = indexAnalyzer.findReferences(for: declaration.name, in: declaration.filePath)
            
            // Risk skoru hesapla
            let riskScore = riskScorer.calculateRiskScore(for: declaration, references: references)
            
            // Açıklama oluştur
            let reason = reachabilityAnalyzer.explainUnused(declaration: declaration)
            
            // Finding oluştur
            let finding = Finding(
                declaration: declaration,
                reason: reason,
                riskScore: riskScore,
                references: references,
                suggestedAction: "Delete declaration",
                isSelected: riskScore <= config.maxAutoSelectRisk
            )
            
            findings.append(finding)
        }
        
        print("   ✓ \(findings.count) bulgu risk skorlaması tamamlandı")
        print("")
        
        // 7. Sonuç oluştur
        let result = AnalysisResult(
            findings: findings,
            totalDeclarations: declarations.count,
            analyzedFiles: swiftFiles,
            entryPoints: entryPoints,
            analysisDate: Date(),
            configUsed: nil
        )
        
        print("✅ Analiz tamamlandı!")
        print("")
        
        return result
    }
    
    /// Swift dosyalarını bul
    private func findSwiftFiles() throws -> [String] {
        var swiftFiles: [String] = []
        let fileManager = FileManager.default
        
        // Workspace içindeki tüm .swift dosyalarını bul
        if let enumerator = fileManager.enumerator(atPath: workingDirectory) {
            while let file = enumerator.nextObject() as? String {
                if file.hasSuffix(".swift") {
                    let fullPath = workingDirectory + "/" + file
                    
                    // Exclude patterns kontrolü
                    var shouldExclude = false
                    for pattern in config.exclude {
                        if fullPath.matches(glob: pattern) {
                            shouldExclude = true
                            break
                        }
                    }
                    
                    if !shouldExclude {
                        swiftFiles.append(fullPath)
                    }
                }
            }
        }
        
        return swiftFiles
    }
    
    /// Xcode workspace için index store yolunu otomatik tespit et
    static func detectIndexStore(
        workspacePath: String?,
        packagePath: String?,
        providedPath: String?
    ) -> String? {
        // 1. Manuel olarak belirtilmişse onu kullan
        if let provided = providedPath {
            return provided
        }
        
        // 2. Xcode workspace varsa DerivedData'dan bul
        if let workspace = workspacePath {
            if let indexPath = IndexStoreAnalyzer.findXcodeIndexStore(for: workspace) {
                return indexPath
            }
        }
        
        // 3. SwiftPM package varsa .build içinde ara
        if let package = packagePath {
            let buildPath = package + "/.build/debug/index/store"
            if FileManager.default.fileExists(atPath: buildPath) {
                return buildPath
            }
        }
        
        return nil
    }
}

