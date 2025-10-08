import Foundation

/// Reachability analizi için graph yapısı
final class ReachabilityAnalyzer {
    private let declarations: [Declaration]
    private let entryPoints: [EntryPoint]
    private let indexAnalyzer: IndexStoreAnalyzer
    private var graph: [UUID: Set<UUID>] = [:] // declaration.id -> referenced declaration ids
    private var reachableDeclarations: Set<UUID> = []
    
    init(
        declarations: [Declaration],
        entryPoints: [EntryPoint],
        indexAnalyzer: IndexStoreAnalyzer
    ) {
        self.declarations = declarations
        self.entryPoints = entryPoints
        self.indexAnalyzer = indexAnalyzer
    }
    
    /// Reachability analizini çalıştır
    func analyze() async -> [Declaration] {
        // 1. Call graph oluştur
        buildCallGraph()
        
        // 2. Entry point'lerden reachability analizi yap
        markReachableFromEntryPoints()
        
        // 3. Erişilemeyen declaration'ları bul
        let unreachable = declarations.filter { declaration in
            !reachableDeclarations.contains(declaration.id)
        }
        
        return unreachable
    }
    
    /// Call graph oluştur (declaration'lar arası referans ilişkileri)
    private func buildCallGraph() {
        let declarationMap = Dictionary(uniqueKeysWithValues: declarations.map { ($0.name, $0) })
        
        for declaration in declarations {
            var references: Set<UUID> = []
            
            // IndexStore'dan bu declaration'ın referans ettiği sembolleri bul
            let refs = indexAnalyzer.findReferences(for: declaration.name, in: declaration.filePath)
            
            for ref in refs {
                // Referans edilen sembolleri declaration'larla eşleştir
                // Basit eşleştirme: aynı dosya ve yakın satırlar
                if let referencedDecl = findDeclaration(at: ref.filePath, line: ref.line, in: declarationMap) {
                    references.insert(referencedDecl.id)
                }
            }
            
            graph[declaration.id] = references
        }
    }
    
    /// Entry point'lerden erişilebilen tüm declaration'ları işaretle
    private func markReachableFromEntryPoints() {
        var queue: [UUID] = entryPoints.map { $0.declaration.id }
        var visited: Set<UUID> = []
        
        // BFS ile tüm erişilebilir declaration'ları bul
        while !queue.isEmpty {
            let currentId = queue.removeFirst()
            
            if visited.contains(currentId) {
                continue
            }
            
            visited.insert(currentId)
            reachableDeclarations.insert(currentId)
            
            // Bu declaration'dan erişilebilen diğer declaration'ları kuyruğa ekle
            if let references = graph[currentId] {
                for refId in references {
                    if !visited.contains(refId) {
                        queue.append(refId)
                    }
                }
            }
        }
    }
    
    /// Belirli bir dosya ve satırda declaration bul
    private func findDeclaration(
        at filePath: String,
        line: Int,
        in declarationMap: [String: Declaration]
    ) -> Declaration? {
        // Önce isimle eşleştir
        for (_, decl) in declarationMap {
            if decl.filePath == filePath && abs(decl.line - line) < 3 {
                return decl
            }
        }
        
        return nil
    }
    
    /// Declaration'ın neden kullanılmadığını açıkla
    func explainUnused(declaration: Declaration) -> String {
        var reasons: [String] = []
        
        // Entry point değil
        let isEntryPoint = entryPoints.contains { $0.declaration.id == declaration.id }
        if !isEntryPoint {
            reasons.append("Entry point değil")
        }
        
        // Hiçbir yerden referans edilmiyor
        let refCount = indexAnalyzer.countReferences(for: declaration)
        if refCount == 0 {
            reasons.append("Hiçbir yerden referans edilmiyor")
        } else {
            reasons.append("\(refCount) referans bulundu ama entry point'lerden erişilemiyor")
        }
        
        // Access level
        if declaration.accessLevel == .private {
            reasons.append("Private erişim seviyesinde")
        }
        
        if reasons.isEmpty {
            return "Kullanılmayan kod olarak tespit edildi"
        }
        
        return reasons.joined(separator: ", ")
    }
    
    /// Declaration'ın özel korumaya ihtiyacı olup olmadığını kontrol et
    func requiresProtection(declaration: Declaration, config: ProtectionsConfig) -> Bool {
        // @objc
        if config.protectObjC && declaration.attributes.contains(where: { $0.contains("@objc") }) {
            return true
        }
        
        // dynamic
        if config.protectDynamic && declaration.modifiers.contains("dynamic") {
            return true
        }
        
        // @IBAction / @IBOutlet
        if config.protectIB && declaration.attributes.contains(where: { 
            $0.contains("@IBAction") || $0.contains("@IBOutlet")
        }) {
            return true
        }
        
        // @NSManaged
        if config.protectNSManaged && declaration.attributes.contains(where: { $0.contains("@NSManaged") }) {
            return true
        }
        
        // @inlinable / @usableFromInline
        if config.protectInlinable && declaration.attributes.contains(where: { 
            $0.contains("@inlinable") || $0.contains("@usableFromInline")
        }) {
            return true
        }
        
        // @_cdecl
        if config.protectCDecl && declaration.attributes.contains(where: { $0.contains("@_cdecl") }) {
            return true
        }
        
        // @_spi
        if config.protectSPI && declaration.attributes.contains(where: { $0.contains("@_spi") }) {
            return true
        }
        
        // SwiftUI Previews
        if config.protectPreviews && declaration.name.hasSuffix("_Previews") {
            return true
        }
        
        return false
    }
}

