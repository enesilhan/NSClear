import Foundation
import SwiftSyntax
import SwiftParser

/// SwiftSyntax kullanarak güvenli kod silme işlemleri
final class CodeRewriter {
    
    /// Findings'i uygula ve dosyaları değiştir
    func applyDeletions(findings: [Finding]) throws -> [String: String] {
        // Dosyalara göre grupla
        let findingsByFile = Dictionary(grouping: findings, by: { $0.declaration.filePath })
        
        var modifiedFiles: [String: String] = [:]
        
        for (filePath, fileFindings) in findingsByFile {
            do {
                let modifiedContent = try deleteDeclarations(in: filePath, findings: fileFindings)
                modifiedFiles[filePath] = modifiedContent
            } catch {
                print("⚠️  Hata: \(filePath) dosyası işlenirken hata oluştu: \(error)")
                throw error
            }
        }
        
        return modifiedFiles
    }
    
    /// Belirli bir dosyadaki declaration'ları sil
    private func deleteDeclarations(in filePath: String, findings: [Finding]) throws -> String {
        let url = URL(fileURLWithPath: filePath)
        let source = try String(contentsOf: url, encoding: .utf8)
        
        // Parse source for validation (not used in current implementation)
        _ = Parser.parse(source: source)
        
        // Byte offset'e göre ters sırala (sondan başa doğru sil)
        let sortedFindings = findings.sorted { $0.declaration.byteOffset > $1.declaration.byteOffset }
        
        var mutableSource = source
        
        for finding in sortedFindings {
            let declaration = finding.declaration
            
            // Güvenlik kontrolü: overlapping ranges
            if hasOverlap(declaration, in: sortedFindings) {
                print("⚠️  Uyarı: \(declaration.name) çakışan range'e sahip, atlanıyor")
                continue
            }
            
            // Byte range hesapla
            let startIndex = mutableSource.utf8.index(mutableSource.utf8.startIndex, offsetBy: declaration.byteOffset)
            let endIndex = mutableSource.utf8.index(startIndex, offsetBy: declaration.byteLength)
            
            // Güvenlik kontrolü: valid range
            guard startIndex < mutableSource.utf8.endIndex && endIndex <= mutableSource.utf8.endIndex else {
                print("⚠️  Uyarı: \(declaration.name) geçersiz byte range'e sahip, atlanıyor")
                continue
            }
            
            // Silme işlemi
            let range = Range(uncheckedBounds: (startIndex, endIndex))
            mutableSource.removeSubrange(range)
            
            // Eğer silme sonrası boş satırlar kaldıysa temizle
            mutableSource = cleanupEmptyLines(mutableSource)
        }
        
        return mutableSource
    }
    
    /// Çakışan range kontrolü
    private func hasOverlap(_ declaration: Declaration, in findings: [Finding]) -> Bool {
        let start = declaration.byteOffset
        let end = declaration.byteOffset + declaration.byteLength
        
        for finding in findings {
            if finding.declaration.id == declaration.id {
                continue
            }
            
            let otherStart = finding.declaration.byteOffset
            let otherEnd = finding.declaration.byteOffset + finding.declaration.byteLength
            
            // Overlap kontrolü
            if (start < otherEnd && end > otherStart) {
                return true
            }
        }
        
        return false
    }
    
    /// Boş satırları temizle
    private func cleanupEmptyLines(_ source: String) -> String {
        let lines = source.components(separatedBy: .newlines)
        
        // Ardışık 3'ten fazla boş satır varsa 2'ye düşür
        var cleaned: [String] = []
        var emptyCount = 0
        
        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                emptyCount += 1
                if emptyCount <= 2 {
                    cleaned.append(line)
                }
            } else {
                emptyCount = 0
                cleaned.append(line)
            }
        }
        
        return cleaned.joined(separator: "\n")
    }
    
    /// Unified diff oluştur
    func generateUnifiedDiff(
        originalContent: String,
        modifiedContent: String,
        filePath: String
    ) -> String {
        let originalLines = originalContent.components(separatedBy: .newlines)
        let modifiedLines = modifiedContent.components(separatedBy: .newlines)
        
        var diff = "--- \(filePath)\n"
        diff += "+++ \(filePath)\n"
        
        let changes = computeDiff(original: originalLines, modified: modifiedLines)
        
        for change in changes {
            diff += change
        }
        
        return diff
    }
    
    /// Basit diff algoritması (Myers diff benzeri)
    private func computeDiff(original: [String], modified: [String]) -> [String] {
        var result: [String] = []
        var i = 0, j = 0
        
        while i < original.count || j < modified.count {
            if i < original.count && j < modified.count && original[i] == modified[j] {
                // Değişmemiş satır
                result.append("  \(original[i])\n")
                i += 1
                j += 1
            } else if i < original.count && (j >= modified.count || original[i] != modified[j]) {
                // Silinen satır
                result.append("- \(original[i])\n")
                i += 1
            } else if j < modified.count {
                // Eklenen satır
                result.append("+ \(modified[j])\n")
                j += 1
            }
        }
        
        return result
    }
    
    /// Dosyaları diske yaz
    func writeModifiedFiles(_ files: [String: String]) throws {
        for (filePath, content) in files {
            try content.write(toFile: filePath, atomically: true, encoding: .utf8)
        }
    }
    
    /// Backup oluştur
    func createBackup(for filePaths: [String]) throws -> String {
        let backupDir = NSTemporaryDirectory() + "nsclear-backup-\(Date().timeIntervalSince1970)"
        try FileManager.default.createDirectory(atPath: backupDir, withIntermediateDirectories: true)
        
        for filePath in filePaths {
            let fileName = URL(fileURLWithPath: filePath).lastPathComponent
            let backupPath = backupDir + "/" + fileName
            try FileManager.default.copyItem(atPath: filePath, toPath: backupPath)
        }
        
        return backupDir
    }
    
    /// Backup'tan geri yükle
    func restoreFromBackup(backupDir: String, to originalPaths: [String]) throws {
        for filePath in originalPaths {
            let fileName = URL(fileURLWithPath: filePath).lastPathComponent
            let backupPath = backupDir + "/" + fileName
            
            if FileManager.default.fileExists(atPath: backupPath) {
                try FileManager.default.removeItem(atPath: filePath)
                try FileManager.default.copyItem(atPath: backupPath, toPath: filePath)
            }
        }
    }
}

/// Rewriter için yardımcı extension'lar
extension String.UTF8View {
    func index(_ i: Index, offsetBy distance: Int) -> Index {
        return index(i, offsetBy: distance, limitedBy: endIndex) ?? endIndex
    }
}

