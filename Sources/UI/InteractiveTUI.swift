import Foundation

/// Terminal-based interactive UI
final class InteractiveTUI {
    private var findings: [Finding]
    private let config: NSClearConfig
    private var selectedIndices: Set<Int> = []
    private var currentPage = 0
    private let pageSize = 10
    
    init(findings: [Finding], config: NSClearConfig) {
        self.findings = findings
        self.config = config
        
        // Otomatik seçim: düşük risk skoruna sahip olanlar
        for (index, finding) in findings.enumerated() {
            if finding.riskScore <= config.maxAutoSelectRisk {
                selectedIndices.insert(index)
            }
        }
    }
    
    /// Interactive TUI'yi başlat
    func run() async -> [Finding] {
        clearScreen()
        
        while true {
            displayFindings()
            displayMenu()
            
            if let choice = readInput() {
                let shouldContinue = await handleChoice(choice)
                if !shouldContinue {
                    break
                }
            }
        }
        
        // Seçili finding'leri döndür
        return selectedIndices.sorted().map { findings[$0] }
    }
    
    private func displayFindings() {
        print("\n╔══════════════════════════════════════════════════════════════════════════════╗")
        print("║                           NSClear - Unused Code Finder                       ║")
        print("╚══════════════════════════════════════════════════════════════════════════════╝")
        print("")
        print("📊 Toplam: \(findings.count) kullanılmayan declaration bulundu")
        print("✅ Seçili: \(selectedIndices.count) declaration")
        print("")
        
        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, findings.count)
        
        if findings.isEmpty {
            print("🎉 Hiç kullanılmayan kod bulunamadı!")
            return
        }
        
        for i in startIndex..<endIndex {
            let finding = findings[i]
            let isSelected = selectedIndices.contains(i)
            let checkbox = isSelected ? "[✓]" : "[ ]"
            let riskIcon = finding.riskLevel.color
            
            print("\(i + 1). \(checkbox) \(riskIcon) \(finding.declaration.kind.displayName): \(finding.declaration.name)")
            print("   📁 \(shortenPath(finding.declaration.filePath)):\(finding.declaration.line)")
            print("   💡 \(finding.reason)")
            print("   🎯 Risk: \(finding.riskScore)/100 (\(finding.riskLevel.rawValue))")
            print("")
        }
        
        if findings.count > pageSize {
            let totalPages = (findings.count + pageSize - 1) / pageSize
            print("📄 Sayfa \(currentPage + 1)/\(totalPages)")
        }
    }
    
    private func displayMenu() {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("🔧 Komutlar:")
        print("  [t <num>]    - Toggle selection (örn: 't 1' veya 't 1-5' veya 't all')")
        print("  [v <num>]    - View details (örn: 'v 1')")
        print("  [d <num>]    - View diff (örn: 'd 1')")
        print("  [n]          - Next page")
        print("  [p]          - Previous page")
        print("  [a]          - Apply deletions")
        print("  [q]          - Quit without applying")
        print("")
        print("Komut girin: ", terminator: "")
    }
    
    private func readInput() -> String? {
        guard let input = readLine() else { return nil }
        return input.trimmingCharacters(in: .whitespaces).lowercased()
    }
    
    private func handleChoice(_ choice: String) async -> Bool {
        let parts = choice.split(separator: " ", maxSplits: 1)
        let command = String(parts.first ?? "")
        let argument = parts.count > 1 ? String(parts[1]) : ""
        
        switch command {
        case "t":
            handleToggle(argument)
        case "v":
            handleViewDetails(argument)
        case "d":
            handleViewDiff(argument)
        case "n":
            handleNextPage()
        case "p":
            handlePreviousPage()
        case "a":
            return await handleApply()
        case "q":
            print("\n👋 Çıkılıyor...")
            return false
        default:
            print("⚠️  Geçersiz komut. Tekrar deneyin.")
        }
        
        clearScreen()
        return true
    }
    
    private func handleToggle(_ argument: String) {
        if argument == "all" {
            // Tümünü seç/seçimi kaldır
            if selectedIndices.count == findings.count {
                selectedIndices.removeAll()
                print("✅ Tüm seçimler kaldırıldı")
            } else {
                selectedIndices = Set(0..<findings.count)
                print("✅ Tümü seçildi")
            }
            return
        }
        
        if argument.contains("-") {
            // Range seçimi (örn: 1-5)
            let rangeParts = argument.split(separator: "-")
            if rangeParts.count == 2,
               let start = Int(rangeParts[0]),
               let end = Int(rangeParts[1]),
               start > 0 && end <= findings.count && start <= end {
                for i in (start - 1)..<end {
                    if selectedIndices.contains(i) {
                        selectedIndices.remove(i)
                    } else {
                        selectedIndices.insert(i)
                    }
                }
                print("✅ \(start)-\(end) arası toggle edildi")
            } else {
                print("⚠️  Geçersiz range. Örnek: t 1-5")
            }
            return
        }
        
        // Tek bir item
        if let index = Int(argument), index > 0 && index <= findings.count {
            let arrayIndex = index - 1
            if selectedIndices.contains(arrayIndex) {
                selectedIndices.remove(arrayIndex)
                print("✅ #\(index) seçimi kaldırıldı")
            } else {
                selectedIndices.insert(arrayIndex)
                print("✅ #\(index) seçildi")
            }
        } else {
            print("⚠️  Geçersiz numara. 1-\(findings.count) arası bir değer girin.")
        }
    }
    
    private func handleViewDetails(_ argument: String) {
        guard let index = Int(argument), index > 0 && index <= findings.count else {
            print("⚠️  Geçersiz numara")
            return
        }
        
        let finding = findings[index - 1]
        let decl = finding.declaration
        
        print("\n" + String(repeating: "=", count: 80))
        print("📋 Declaration Detayları")
        print(String(repeating: "=", count: 80))
        print("")
        print("🏷️  İsim: \(decl.name)")
        print("📦 Tür: \(decl.kind.displayName)")
        print("📁 Dosya: \(decl.filePath)")
        print("📍 Konum: Satır \(decl.line), Sütun \(decl.column)")
        print("🔐 Erişim: \(decl.accessLevel.rawValue)")
        print("🏷️  Attributes: \(decl.attributes.isEmpty ? "-" : decl.attributes.joined(separator: ", "))")
        print("🔧 Modifiers: \(decl.modifiers.isEmpty ? "-" : decl.modifiers.joined(separator: ", "))")
        print("")
        print("💡 Sebep: \(finding.reason)")
        print("")
        print("🎯 Risk Skoru: \(finding.riskScore)/100")
        print("⚠️  Risk Seviyesi: \(finding.riskLevel.rawValue)")
        print("")
        print("📌 Referanslar: \(finding.references.count) adet")
        for ref in finding.references.prefix(5) {
            print("   • \(shortenPath(ref.filePath)):\(ref.line)")
        }
        if finding.references.count > 5 {
            print("   ... ve \(finding.references.count - 5) tane daha")
        }
        print("")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        print("📋 ÖNERİLEN AKSİYON:")
        print("")
        print(finding.suggestedAction)
        print("")
        print(String(repeating: "=", count: 80))
        print("\nDevam etmek için Enter'a basın...")
        _ = readLine()
    }
    
    private func handleViewDiff(_ argument: String) {
        guard let index = Int(argument), index > 0 && index <= findings.count else {
            print("⚠️  Geçersiz numara")
            return
        }
        
        let finding = findings[index - 1]
        
        print("\n" + String(repeating: "=", count: 80))
        print("📝 Diff Preview: \(finding.declaration.name)")
        print(String(repeating: "=", count: 80))
        print("")
        
        // Dosya içeriğini oku ve diff göster
        if let content = try? String(contentsOfFile: finding.declaration.filePath) {
            let lines = content.components(separatedBy: .newlines)
            let startLine = max(0, finding.declaration.line - 5)
            let endLine = min(lines.count, finding.declaration.line + 10)
            
            for i in startLine..<endLine {
                let lineNumber = i + 1
                let prefix: String
                if lineNumber >= finding.declaration.line && 
                   lineNumber < finding.declaration.line + (finding.declaration.byteLength / 80) {
                    prefix = "- "
                } else {
                    prefix = "  "
                }
                print("\(String(format: "%4d", lineNumber)) \(prefix)\(lines[i])")
            }
        }
        
        print("")
        print(String(repeating: "=", count: 80))
        print("\nDevam etmek için Enter'a basın...")
        _ = readLine()
    }
    
    private func handleNextPage() {
        let totalPages = (findings.count + pageSize - 1) / pageSize
        if currentPage < totalPages - 1 {
            currentPage += 1
        } else {
            print("⚠️  Son sayfadasınız")
        }
    }
    
    private func handlePreviousPage() {
        if currentPage > 0 {
            currentPage -= 1
        } else {
            print("⚠️  İlk sayfadasınız")
        }
    }
    
    private func handleApply() async -> Bool {
        if selectedIndices.isEmpty {
            print("\n⚠️  Hiçbir declaration seçilmedi. Çıkılıyor...")
            return false
        }
        
        print("\n" + String(repeating: "=", count: 80))
        print("⚠️  UYARI: Değişiklikler Uygulanacak")
        print(String(repeating: "=", count: 80))
        print("")
        print("📊 \(selectedIndices.count) declaration silinecek")
        print("")
        
        // Risk dağılımını göster
        var riskDistribution: [RiskLevel: Int] = [:]
        for index in selectedIndices {
            let level = findings[index].riskLevel
            riskDistribution[level, default: 0] += 1
        }
        
        print("🎯 Risk Dağılımı:")
        for (level, count) in riskDistribution.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            print("   \(level.color) \(level.rawValue): \(count) adet")
        }
        print("")
        print("❓ Devam etmek istediğinizden emin misiniz? (yes/no): ", terminator: "")
        
        guard let confirmation = readLine()?.lowercased(), confirmation == "yes" || confirmation == "y" else {
            print("❌ İşlem iptal edildi")
            return true
        }
        
        print("\n✅ Değişiklikler uygulanacak...")
        return false // TUI'den çık ve uygula
    }
    
    // MARK: - Helper Methods
    
    private func clearScreen() {
        print("\u{1B}[2J\u{1B}[H", terminator: "")
    }
    
    private func shortenPath(_ path: String) -> String {
        let components = path.components(separatedBy: "/")
        if components.count > 3 {
            return ".../" + components.suffix(3).joined(separator: "/")
        }
        return path
    }
}

