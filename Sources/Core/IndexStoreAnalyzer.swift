import Foundation
import IndexStoreDB

/// IndexStoreDB kullanarak sembol referanslarını analiz eden sınıf
final class IndexStoreAnalyzer {
    private let indexStore: IndexStoreDB?
    private let config: NSClearConfig
    
    init(indexStorePath: String?, config: NSClearConfig = NSClearConfig()) throws {
        self.config = config
        
        if let path = indexStorePath {
            // Belirtilen index store'u kullan
            let libPath = try IndexStoreAnalyzer.findLibIndexStore()
            self.indexStore = try IndexStoreDB(
                storePath: path,
                databasePath: NSTemporaryDirectory() + "nsclear-index.db",
                library: IndexStoreLibrary(dylibPath: libPath)
            )
        } else {
            // Index store bulunamadı - bazı analizler yapılamayacak
            self.indexStore = nil
            print("⚠️  Index store bulunamadı. Referans analizi sınırlı olacak.")
        }
    }
    
    /// Sembol için tüm referansları bul
    func findReferences(for symbolName: String, in filePath: String) -> [Reference] {
        guard let indexStore = indexStore else {
            return []
        }
        
        var references: [Reference] = []
        
        // IndexStore'dan sembolleri ara
        indexStore.forEachCanonicalSymbolOccurrence(
            containing: symbolName,
            anchorStart: false,
            anchorEnd: false,
            subsequence: false,
            ignoreCase: false
        ) { occurrence in
            // Sadece referansları al (definition değil)
            if occurrence.roles.contains(.reference) || occurrence.roles.contains(.call) {
                let ref = Reference(
                    filePath: occurrence.location.path,
                    line: occurrence.location.line,
                    column: occurrence.location.utf8Column,
                    context: "" // Context dosyadan okunabilir
                )
                references.append(ref)
            }
            return true
        }
        
        return references
    }
    
    /// Declaration için referans sayısını bul
    func countReferences(for declaration: Declaration) -> Int {
        let refs = findReferences(for: declaration.name, in: declaration.filePath)
        // Kendi tanımını çıkar
        return refs.filter { $0.filePath != declaration.filePath || $0.line != declaration.line }.count
    }
    
    /// Tüm entry point'leri bul
    func findEntryPoints(in declarations: [Declaration]) -> [EntryPoint] {
        var entryPoints: [EntryPoint] = []
        
        for declaration in declarations {
            // @main attribute
            if config.entryPoints.detectMain && declaration.attributes.contains(where: { $0.contains("@main") }) {
                entryPoints.append(EntryPoint(declaration: declaration, entryPointKind: .main))
            }
            
            // UIApplicationMain
            if config.entryPoints.detectUIApplicationMain && 
               (declaration.attributes.contains(where: { $0.contains("@UIApplicationMain") }) ||
                declaration.attributes.contains(where: { $0.contains("@NSApplicationMain") })) {
                entryPoints.append(EntryPoint(declaration: declaration, entryPointKind: .uiApplicationMain))
            }
            
            // SwiftUI.App
            if config.entryPoints.detectSwiftUIApp && declaration.kind == .struct {
                // App protocol conformance'ı kontrol et (IndexStore'dan)
                if conformsToSwiftUIApp(declaration) {
                    entryPoints.append(EntryPoint(declaration: declaration, entryPointKind: .swiftUIApp))
                }
            }
            
            // Public API
            if config.entryPoints.includePublicAPI && 
               (declaration.accessLevel == .public || declaration.accessLevel == .open) {
                entryPoints.append(EntryPoint(declaration: declaration, entryPointKind: .publicAPI))
            }
            
            // ObjC symbols
            if config.entryPoints.includeObjCSymbols && 
               (declaration.attributes.contains(where: { $0.contains("@objc") }) || 
                declaration.modifiers.contains("dynamic")) {
                entryPoints.append(EntryPoint(declaration: declaration, entryPointKind: .objcSymbol))
            }
            
            // Test entry points
            if config.entryPoints.includeTestEntryPoints && isTestEntryPoint(declaration) {
                entryPoints.append(EntryPoint(declaration: declaration, entryPointKind: .testEntryPoint))
            }
        }
        
        return entryPoints
    }
    
    /// Declaration'ın protocol witness olup olmadığını kontrol et
    func isProtocolWitness(declaration: Declaration) -> Bool {
        guard let indexStore = indexStore else { return false }
        
        var isWitness = false
        
        indexStore.forEachCanonicalSymbolOccurrence(
            containing: declaration.name,
            anchorStart: false,
            anchorEnd: false,
            subsequence: false,
            ignoreCase: false
        ) { occurrence in
            if occurrence.symbol.kind == .instanceMethod || 
               occurrence.symbol.kind == .instanceProperty {
                if occurrence.roles.contains(.overrideOf) {
                    isWitness = true
                    return false // Stop iteration
                }
            }
            return true
        }
        
        return isWitness
    }
    
    // MARK: - Helper Methods
    
    private func conformsToSwiftUIApp(_ declaration: Declaration) -> Bool {
        // Basit kontrol: dosyada "App" protocol conformance var mı?
        // Daha kesin kontrol için IndexStore kullanılabilir
        guard let indexStore = indexStore else {
            // Index store yoksa dosya içeriğine bak
            return checkSwiftUIAppInFile(declaration.filePath)
        }
        
        // IndexStore'dan App protocol conformance kontrolü
        var conformsToApp = false
        
        indexStore.forEachCanonicalSymbolOccurrence(
            containing: declaration.name,
            anchorStart: true,
            anchorEnd: false,
            subsequence: false,
            ignoreCase: false
        ) { occurrence in
            if occurrence.symbol.kind == .struct {
                // Check for protocol conformance (simplified)
                conformsToApp = true
                return false
            }
            return true
        }
        
        return conformsToApp
    }
    
    private func checkSwiftUIAppInFile(_ filePath: String) -> Bool {
        guard let content = try? String(contentsOfFile: filePath) else {
            return false
        }
        
        // Basit regex kontrolü
        let pattern = #":\s*App\s*\{"#
        return content.range(of: pattern, options: .regularExpression) != nil
    }
    
    private func isTestEntryPoint(_ declaration: Declaration) -> Bool {
        // XCTest test methodları
        if declaration.filePath.lowercased().contains("test") {
            if declaration.kind == .method && declaration.name.hasPrefix("test") {
                return true
            }
            if declaration.attributes.contains(where: { $0.contains("@Test") }) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Static Helpers
    
    /// libIndexStore.dylib yolunu bul
    static func findLibIndexStore() throws -> String {
        // Xcode içindeki libIndexStore.dylib'i bul
        let task = Process()
        task.launchPath = "/usr/bin/xcrun"
        task.arguments = ["--find", "swift"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let swiftPath = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw NSError(domain: "NSClear", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Swift compiler bulunamadı"
            ])
        }
        
        // /usr/bin/swift -> ../lib/libIndexStore.dylib
        let swiftURL = URL(fileURLWithPath: swiftPath)
        let libPath = swiftURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("lib")
            .appendingPathComponent("libIndexStore.dylib")
            .path
        
        if FileManager.default.fileExists(atPath: libPath) {
            return libPath
        }
        
        // Alternatif: Toolchain içinde ara
        let toolchainLibPath = swiftURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("lib")
            .appendingPathComponent("libIndexStore.dylib")
            .path
        
        if FileManager.default.fileExists(atPath: toolchainLibPath) {
            return toolchainLibPath
        }
        
        throw NSError(domain: "NSClear", code: 2, userInfo: [
            NSLocalizedDescriptionKey: "libIndexStore.dylib bulunamadı"
        ])
    }
    
    /// Xcode DerivedData'daki index store yolunu otomatik tespit et
    static func findXcodeIndexStore(for workspacePath: String) -> String? {
        let derivedDataPath = NSHomeDirectory() + "/Library/Developer/Xcode/DerivedData"
        
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: derivedDataPath) else {
            return nil
        }
        
        // Workspace/project adına göre DerivedData klasörünü bul
        let workspaceName = URL(fileURLWithPath: workspacePath).deletingPathExtension().lastPathComponent
        
        for item in contents {
            if item.hasPrefix(workspaceName) {
                let indexPath = "\(derivedDataPath)/\(item)/Index/DataStore"
                if FileManager.default.fileExists(atPath: indexPath) {
                    return indexPath
                }
            }
        }
        
        return nil
    }
}

