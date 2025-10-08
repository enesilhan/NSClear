import Foundation

/// Ana analiz orkestratörü - tüm bileşenleri koordine eder
final class Analyzer {
    private let config: NSClearConfig
    private let workingDirectory: String
    private let indexStorePath: String?
    private let useFastMode: Bool
    
    init(
        workingDirectory: String,
        indexStorePath: String? = nil,
        config: NSClearConfig = NSClearConfig(),
        useFastMode: Bool = false
    ) {
        self.workingDirectory = workingDirectory
        self.indexStorePath = indexStorePath
        self.config = config
        self.useFastMode = useFastMode || indexStorePath == nil
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
        let declarations: [Declaration]
        
        if useFastMode {
            print("   ⚡ Fast mode: Basit regex-based parsing")
            let simpleAnalyzer = SimpleSyntaxAnalyzer(config: config)
            var allDeclarations: [Declaration] = []
            for file in swiftFiles {
                let fileDecls = simpleAnalyzer.analyzeFile(at: file)
                allDeclarations.append(contentsOf: fileDecls)
            }
            declarations = allDeclarations
        } else {
            print("   🔬 Full mode: SwiftSyntax-based parsing")
            let syntaxAnalyzer = SyntaxAnalyzer(config: config)
            declarations = try await syntaxAnalyzer.analyzeFiles(at: swiftFiles)
        }
        
        print("   ✓ \(declarations.count) declaration bulundu")
        
        // 3. IndexStore hazırla (sadece full mode'da)
        let indexAnalyzer: IndexStoreAnalyzer?
        let entryPoints: [EntryPoint]
        let unreachable: [Declaration]
        
        if useFastMode {
            print("📊 Index store atlanıyor (fast mode)")
            indexAnalyzer = nil
            
            // Fast mode: Entry point'leri basit pattern matching ile bul
            print("🎯 Entry point'ler belirleniyor (basit mode)...")
            entryPoints = findBasicEntryPoints(in: declarations)
            print("   ✓ \(entryPoints.count) entry point bulundu")
            
            // Fast mode: Basit reachability (sadece syntax-based)
            print("🔗 Basit reachability analizi...")
            unreachable = findBasicUnreachable(declarations: declarations, entryPoints: entryPoints)
            print("   ✓ \(unreachable.count) erişilemeyen declaration tespit edildi")
        } else {
            print("📊 Index store hazırlanıyor...")
            indexAnalyzer = try IndexStoreAnalyzer(
                indexStorePath: indexStorePath,
                config: config
            )
            print("   ✓ Index store hazır")
            
            // 4. Entry point'leri bul
            print("🎯 Entry point'ler belirleniyor...")
            entryPoints = indexAnalyzer!.findEntryPoints(in: declarations)
            print("   ✓ \(entryPoints.count) entry point bulundu")
            
            // 5. Reachability analizi
            print("🔗 Reachability analizi yapılıyor...")
            let reachabilityAnalyzer = ReachabilityAnalyzer(
                declarations: declarations,
                entryPoints: entryPoints,
                indexAnalyzer: indexAnalyzer!
            )
            unreachable = await reachabilityAnalyzer.analyze()
            print("   ✓ \(unreachable.count) erişilemeyen declaration tespit edildi")
        }
        
        // 6. Risk skorlaması
        print("🎯 Risk skorlaması yapılıyor...")
        let riskScorer = RiskScorer(config: config.riskScoring)
        var findings: [Finding] = []
        
        for declaration in unreachable {
            // Koruma kontrolü (basit)
            if declaration.hasProtectedAttributes() || declaration.hasProtectedModifiers() {
                print("   ⚠️  Korunuyor: \(declaration.name) (protected attribute/modifier)")
                continue
            }
            
            // Public API kontrolü
            if !config.checkPublicAPI && 
               (declaration.accessLevel == .public || declaration.accessLevel == .open) {
                continue
            }
            
            // Referansları bul (varsa)
            let references = indexAnalyzer?.findReferences(for: declaration.name, in: declaration.filePath) ?? []
            
            // Risk skoru hesapla
            let riskScore = riskScorer.calculateRiskScore(for: declaration, references: references)
            
            // Detaylı açıklama ve öneri oluştur
            let reason = RiskDescriptor.generateDetailedReason(
                for: declaration,
                riskScore: riskScore,
                useFastMode: useFastMode,
                references: references
            )
            
            let suggestedAction = RiskDescriptor.suggestedAction(
                for: riskScore,
                declaration: declaration
            )
            
            // Finding oluştur
            let finding = Finding(
                declaration: declaration,
                reason: reason,
                riskScore: riskScore,
                references: references,
                suggestedAction: suggestedAction,
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
        if let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: workingDirectory),
            includingPropertiesForKeys: nil
        ) {
            while let fileURL = enumerator.nextObject() as? URL {
                let file = fileURL.path
                let relativePath = file.replacingOccurrences(of: workingDirectory + "/", with: "")
                
                // System/derived directories'i skip et
                if shouldSkipDirectory(relativePath) {
                    enumerator.skipDescendants()
                    continue
                }
                
                // Sadece .swift dosyalarını al (.swiftinterface, .swiftmodule değil)
                if file.hasSuffix(".swift") && !file.hasSuffix(".swiftinterface") {
                    // Sistem dosyalarını atla
                    if isSystemOrDerivedFile(file) {
                        continue
                    }
                    
                    // Exclude patterns kontrolü
                    var shouldExclude = false
                    for pattern in config.exclude {
                        if file.matches(glob: pattern) {
                            shouldExclude = true
                            break
                        }
                    }
                    
                    if !shouldExclude {
                        swiftFiles.append(file)
                    }
                }
            }
        }
        
        return swiftFiles
    }
    
    /// Directory'yi skip etmeli mi?
    private func shouldSkipDirectory(_ path: String) -> Bool {
        let skipDirs = [
            "DerivedData",
            "Build",
            ".build",
            "Pods",
            "Carthage",
            ".swiftpm",
            "xcuserdata"
        ]
        
        for skipDir in skipDirs {
            if path.contains(skipDir) || path.hasPrefix(".") {
                return true
            }
        }
        
        return false
    }
    
    /// Sistem veya derived dosya mı kontrol et
    private func isSystemOrDerivedFile(_ path: String) -> Bool {
        let excludePaths = [
            "DerivedData",
            "Build/Products",
            "Build/Intermediates",
            ".build",
            "Pods/",
            "Carthage/",
            ".swiftpm",
            "/Library/Developer",
            "/Applications/Xcode.app"
        ]
        
        for excludePath in excludePaths {
            if path.contains(excludePath) {
                return true
            }
        }
        
        return false
    }
    
    /// Basit entry point bulma (fast mode)
    private func findBasicEntryPoints(in declarations: [Declaration]) -> [EntryPoint] {
        var entryPoints: [EntryPoint] = []
        
        for declaration in declarations {
            // @main attribute
            if declaration.attributes.contains(where: { $0.contains("@main") }) {
                entryPoints.append(EntryPoint(declaration: declaration, entryPointKind: .main))
            }
            
            // @UIApplicationMain / @NSApplicationMain
            if declaration.attributes.contains(where: { 
                $0.contains("@UIApplicationMain") || $0.contains("@NSApplicationMain") 
            }) {
                entryPoints.append(EntryPoint(declaration: declaration, entryPointKind: .uiApplicationMain))
            }
            
            // SwiftUI App (struct ile : App)
            if declaration.kind == .struct && declaration.name.hasSuffix("App") {
                entryPoints.append(EntryPoint(declaration: declaration, entryPointKind: .swiftUIApp))
            }
            
            // Public/Open API
            if declaration.accessLevel == .public || declaration.accessLevel == .open {
                entryPoints.append(EntryPoint(declaration: declaration, entryPointKind: .publicAPI))
            }
            
            // @objc/dynamic
            if declaration.attributes.contains(where: { $0.contains("@objc") }) ||
               declaration.modifiers.contains("dynamic") {
                entryPoints.append(EntryPoint(declaration: declaration, entryPointKind: .objcSymbol))
            }
        }
        
        return entryPoints
    }
    
    /// Basit unreachable bulma (fast mode - conservative)
    private func findBasicUnreachable(declarations: [Declaration], entryPoints: [EntryPoint]) -> [Declaration] {
        let entryPointIds = Set(entryPoints.map { $0.declaration.id })
        
        // Fast mode: Sadece entry point olmayan ve korumalı olmayan declaration'ları döndür
        return declarations.filter { declaration in
            // Entry point değilse
            !entryPointIds.contains(declaration.id) &&
            // Korumalı değilse
            !declaration.hasProtectedAttributes() &&
            !declaration.hasProtectedModifiers() &&
            // Private veya internal
            (declaration.accessLevel == .private || declaration.accessLevel == .internal)
        }
    }
    
    /// Xcode workspace/project için index store yolunu otomatik tespit et
    static func detectIndexStore(
        workspacePath: String?,
        projectPath: String?,
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
        
        // 3. Xcode project varsa DerivedData'dan bul
        if let project = projectPath {
            if let indexPath = IndexStoreAnalyzer.findXcodeIndexStore(for: project) {
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

