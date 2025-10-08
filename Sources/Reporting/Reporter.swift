import Foundation

/// Analiz sonuçlarını raporlayan sınıf
final class Reporter {
    private let result: AnalysisResult
    
    init(result: AnalysisResult) {
        self.result = result
    }
    
    /// JSON formatında rapor oluştur
    func generateJSONReport() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(result)
        guard let json = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "NSClear", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "JSON encoding hatası"
            ])
        }
        
        return json
    }
    
    /// Text formatında rapor oluştur
    func generateTextReport() -> String {
        var report = ""
        
        report += "╔══════════════════════════════════════════════════════════════════════════════╗\n"
        report += "║                        NSClear - Analiz Raporu                               ║\n"
        report += "╚══════════════════════════════════════════════════════════════════════════════╝\n"
        report += "\n"
        
        // Özet
        report += "📊 ÖZET\n"
        report += String(repeating: "─", count: 80) + "\n"
        report += "Tarih: \(formatDate(result.analysisDate))\n"
        report += "Toplam Declaration: \(result.totalDeclarations)\n"
        report += "Kullanılmayan: \(result.unusedCount)\n"
        report += "Kullanım Oranı: \(String(format: "%.1f", result.usagePercentage))%\n"
        report += "Analiz Edilen Dosya: \(result.analyzedFiles.count)\n"
        report += "Entry Point: \(result.entryPoints.count)\n"
        report += "\n"
        
        // Risk dağılımı
        report += "🎯 RİSK DAĞILIMI\n"
        report += String(repeating: "─", count: 80) + "\n"
        let riskDistribution = calculateRiskDistribution()
        for (level, count) in riskDistribution.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            let percentage = Double(count) / Double(result.unusedCount) * 100
            report += "\(level.color) \(level.rawValue.padding(toLength: 12, withPad: " ", startingAt: 0)): "
            report += "\(count) adet (\(String(format: "%.1f", percentage))%)\n"
        }
        report += "\n"
        
        // Dosya bazında dağılım
        report += "📁 DOSYA BAZINDA DAĞILIM\n"
        report += String(repeating: "─", count: 80) + "\n"
        let fileDistribution = calculateFileDistribution()
        for (file, count) in fileDistribution.sorted(by: { $0.value > $1.value }).prefix(10) {
            report += "\(shortenPath(file).padding(toLength: 60, withPad: " ", startingAt: 0)): \(count)\n"
        }
        if fileDistribution.count > 10 {
            report += "... ve \(fileDistribution.count - 10) dosya daha\n"
        }
        report += "\n"
        
        // Tür bazında dağılım
        report += "📦 TÜR BAZINDA DAĞILIM\n"
        report += String(repeating: "─", count: 80) + "\n"
        let kindDistribution = calculateKindDistribution()
        for (kind, count) in kindDistribution.sorted(by: { $0.value > $1.value }) {
            report += "\(kind.displayName.padding(toLength: 20, withPad: " ", startingAt: 0)): \(count)\n"
        }
        report += "\n"
        
        // Detaylı bulgular
        report += "📋 DETAYLI BULGULAR\n"
        report += String(repeating: "─", count: 80) + "\n"
        
        for (index, finding) in result.findings.enumerated().prefix(50) {
            report += "\n\(index + 1). \(finding.riskLevel.color) \(finding.declaration.kind.displayName): \(finding.declaration.name)\n"
            report += "   📁 \(shortenPath(finding.declaration.filePath)):\(finding.declaration.line)\n"
            report += "   💡 \(finding.reason)\n"
            report += "   🎯 Risk: \(finding.riskScore)/100 (\(finding.riskLevel.rawValue))\n"
        }
        
        if result.findings.count > 50 {
            report += "\n... ve \(result.findings.count - 50) bulgu daha\n"
        }
        
        report += "\n"
        report += String(repeating: "═", count: 80) + "\n"
        
        return report
    }
    
    /// Xcode diagnostics formatında rapor (compiler warning formatı)
    func generateXcodeDiagnostics() -> String {
        var diagnostics = ""
        
        for finding in result.findings {
            let decl = finding.declaration
            let severity = finding.riskScore > 50 ? "warning" : "note"
            
            diagnostics += "\(decl.filePath):\(decl.line):\(decl.column): "
            diagnostics += "\(severity): [NSClear] Unused \(decl.kind.rawValue): '\(decl.name)' "
            diagnostics += "(Risk: \(finding.riskScore)/100)\n"
            
            // Fix-it suggestion
            diagnostics += "\(decl.filePath):\(decl.line):\(decl.column): "
            diagnostics += "note: \(finding.suggestedAction)\n"
        }
        
        return diagnostics
    }
    
    /// Markdown formatında rapor oluştur
    func generateMarkdownReport() -> String {
        var markdown = ""
        
        markdown += "# NSClear - Analiz Raporu\n\n"
        markdown += "**Tarih:** \(formatDate(result.analysisDate))\n\n"
        
        // Özet tablosu
        markdown += "## 📊 Özet\n\n"
        markdown += "| Metrik | Değer |\n"
        markdown += "|--------|-------|\n"
        markdown += "| Toplam Declaration | \(result.totalDeclarations) |\n"
        markdown += "| Kullanılmayan | \(result.unusedCount) |\n"
        markdown += "| Kullanım Oranı | \(String(format: "%.1f", result.usagePercentage))% |\n"
        markdown += "| Analiz Edilen Dosya | \(result.analyzedFiles.count) |\n"
        markdown += "| Entry Point | \(result.entryPoints.count) |\n\n"
        
        // Risk dağılımı
        markdown += "## 🎯 Risk Dağılımı\n\n"
        let riskDistribution = calculateRiskDistribution()
        markdown += "| Risk Seviyesi | Sayı | Yüzde |\n"
        markdown += "|---------------|------|-------|\n"
        for (level, count) in riskDistribution.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            let percentage = Double(count) / Double(result.unusedCount) * 100
            markdown += "| \(level.color) \(level.rawValue) | \(count) | \(String(format: "%.1f", percentage))% |\n"
        }
        markdown += "\n"
        
        // En çok kullanılmayan dosyalar
        markdown += "## 📁 En Çok Kullanılmayan Kod İçeren Dosyalar\n\n"
        let fileDistribution = calculateFileDistribution()
        markdown += "| Dosya | Kullanılmayan Declaration |\n"
        markdown += "|-------|---------------------------|\n"
        for (file, count) in fileDistribution.sorted(by: { $0.value > $1.value }).prefix(10) {
            markdown += "| `\(shortenPath(file))` | \(count) |\n"
        }
        markdown += "\n"
        
        // Bulgular
        markdown += "## 📋 Bulgular\n\n"
        for finding in result.findings.prefix(20) {
            let decl = finding.declaration
            markdown += "### \(finding.riskLevel.color) `\(decl.name)` - \(decl.kind.displayName)\n\n"
            markdown += "- **Dosya:** `\(shortenPath(decl.filePath)):\(decl.line)`\n"
            markdown += "- **Sebep:** \(finding.reason)\n"
            markdown += "- **Risk Skoru:** \(finding.riskScore)/100 (\(finding.riskLevel.rawValue))\n"
            markdown += "- **Erişim:** `\(decl.accessLevel.rawValue)`\n"
            if !decl.attributes.isEmpty {
                markdown += "- **Attributes:** \(decl.attributes.joined(separator: ", "))\n"
            }
            markdown += "\n"
        }
        
        if result.findings.count > 20 {
            markdown += "_... ve \(result.findings.count - 20) bulgu daha_\n\n"
        }
        
        return markdown
    }
    
    /// Raporu dosyaya yaz
    func writeReport(to path: String, format: ReportFormat) throws {
        let content: String
        
        switch format {
        case .json:
            content = try generateJSONReport()
        case .text:
            content = generateTextReport()
        case .xcode:
            content = generateXcodeDiagnostics()
        case .markdown:
            content = generateMarkdownReport()
        }
        
        try content.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    // MARK: - Helper Methods
    
    private func calculateRiskDistribution() -> [RiskLevel: Int] {
        var distribution: [RiskLevel: Int] = [:]
        for finding in result.findings {
            distribution[finding.riskLevel, default: 0] += 1
        }
        return distribution
    }
    
    private func calculateFileDistribution() -> [String: Int] {
        var distribution: [String: Int] = [:]
        for finding in result.findings {
            distribution[finding.declaration.filePath, default: 0] += 1
        }
        return distribution
    }
    
    private func calculateKindDistribution() -> [DeclarationKind: Int] {
        var distribution: [DeclarationKind: Int] = [:]
        for finding in result.findings {
            distribution[finding.declaration.kind, default: 0] += 1
        }
        return distribution
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func shortenPath(_ path: String) -> String {
        let components = path.components(separatedBy: "/")
        if components.count > 3 {
            return ".../" + components.suffix(3).joined(separator: "/")
        }
        return path
    }
}

/// Rapor formatları
enum ReportFormat: String, CaseIterable {
    case json
    case text
    case xcode
    case markdown
}

