import Foundation
import ArgumentParser

/// NSClear - Swift projelerinde kullanılmayan kodu bulan ve temizleyen CLI aracı
@main
@available(macOS 13.0, *)
struct NSClear: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "nsclear",
        abstract: "Swift projelerinde kullanılmayan kodu bulan ve temizleyen interaktif CLI aracı",
        version: "1.0.0",
        subcommands: [Scan.self, Apply.self, Report.self],
        defaultSubcommand: Scan.self
    )
}

// MARK: - Scan Command

extension NSClear {
    struct Scan: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Kullanılmayan kodu tara ve analiz et"
        )
        
        @Option(name: .long, help: "Xcode workspace yolu (.xcworkspace)")
        var workspace: String?
        
        @Option(name: .long, help: "Xcode project yolu (.xcodeproj)")
        var project: String?
        
        @Option(name: .long, help: "Xcode scheme adı")
        var scheme: String?
        
        @Option(name: .long, help: "SwiftPM package yolu")
        var packagePath: String?
        
        @Option(name: .long, help: "Index store yolu (manuel)")
        var indexStorePath: String?
        
        @Option(name: .long, help: "Konfigürasyon dosyası yolu")
        var config: String = ".nsclear.yml"
        
        @Option(name: .long, help: "Çıktı formatı (json|text|xcode|markdown)")
        var format: String = "text"
        
        @Flag(name: .long, help: "İnteraktif TUI modunu başlat")
        var interactive: Bool = false
        
        @Flag(name: .long, help: "Değişiklikleri uygula (dikkatli kullanın!)")
        var apply: Bool = false
        
        @Option(name: .long, help: "Raporu dosyaya yaz")
        var writeReport: String?
        
        @Option(name: .long, help: "Maksimum otomatik seçim risk skoru")
        var maxRisk: Int?
        
        @Flag(name: .long, help: "Verbose output")
        var verbose: Bool = false
        
        @Flag(name: .long, help: "Fast mode (syntax-only, no index store)")
        var fast: Bool = false
        
        mutating func run() async throws {
            // Working directory belirle
            let workingDir = packagePath ?? FileManager.default.currentDirectoryPath
            
            // Konfigürasyon yükle
            let configuration: NSClearConfig
            if FileManager.default.fileExists(atPath: config) {
                configuration = try NSClearConfig.load(from: config)
                print("📄 Konfigürasyon yüklendi: \(config)")
            } else {
                configuration = NSClearConfig()
                print("⚠️  Konfigürasyon dosyası bulunamadı, varsayılan ayarlar kullanılıyor")
            }
            
            // Override config with command line arguments
            var finalConfig = configuration
            if let maxRisk = maxRisk {
                finalConfig.maxAutoSelectRisk = maxRisk
            }
            
            // Index store yolunu tespit et (fast mode'da skip)
            let indexStore: String?
            
            if fast {
                print("🚀 Fast mode: Sadece syntax analizi (index store kullanılmıyor)")
                print("   ⚡ Daha hızlı ama daha az doğru")
                print("   💡 Tam analiz için --fast flag'ini kaldırın")
                print("")
                indexStore = nil
            } else {
                indexStore = Analyzer.detectIndexStore(
                    workspacePath: workspace,
                    projectPath: project,
                    packagePath: packagePath,
                    providedPath: indexStorePath
                )
                
                if indexStore == nil {
                    print("⚠️  Index store bulunamadı. Referans analizi sınırlı olacak.")
                    print("💡 Index store oluşturmak için:")
                    if let ws = workspace {
                        print("   xcodebuild -workspace \(ws) -scheme \(scheme ?? "YourScheme") build")
                    } else if let proj = project {
                        print("   xcodebuild -project \(proj) -scheme \(scheme ?? "YourScheme") build")
                    } else {
                        print("   swift build -Xswiftc -index-store-path -Xswiftc .build/index/store")
                    }
                    print("")
                    print("🚀 Alternatif: Fast mode kullanın (--fast)")
                    print("")
                }
            }
            
            // Analizi çalıştır
            let analyzer = Analyzer(
                workingDirectory: workingDir,
                indexStorePath: indexStore,
                config: finalConfig,
                useFastMode: fast
            )
            
            let result = try await analyzer.analyze()
            
            // Sonuçları göster
            displaySummary(result)
            
            // Rapor oluştur
            if let reportPath = writeReport {
                let reportFormat = ReportFormat(rawValue: format) ?? .text
                let reporter = Reporter(result: result)
                try reporter.writeReport(to: reportPath, format: reportFormat)
                print("✅ Rapor yazıldı: \(reportPath)")
            } else if !interactive {
                // Interactive mode değilse ekrana yazdır
                let reporter = Reporter(result: result)
                switch format {
                case "json":
                    print(try reporter.generateJSONReport())
                case "xcode":
                    print(reporter.generateXcodeDiagnostics())
                case "markdown":
                    print(reporter.generateMarkdownReport())
                default:
                    print(reporter.generateTextReport())
                }
            }
            
            // Interactive mode
            if interactive {
                let tui = InteractiveTUI(findings: result.findings, config: finalConfig)
                let selectedFindings = await tui.run()
                
                if apply && !selectedFindings.isEmpty {
                    try await applyDeletions(
                        findings: selectedFindings,
                        workingDir: workingDir,
                        config: finalConfig
                    )
                }
            } else if apply {
                // Non-interactive apply
                let selectedFindings = result.findings.filter { $0.riskScore <= finalConfig.maxAutoSelectRisk }
                if !selectedFindings.isEmpty {
                    try await applyDeletions(
                        findings: selectedFindings,
                        workingDir: workingDir,
                        config: finalConfig
                    )
                }
            }
        }
        
        private func displaySummary(_ result: AnalysisResult) {
            print("╔══════════════════════════════════════════════════════════════════╗")
            print("║                    ANALIZ ÖZET                                   ║")
            print("╚══════════════════════════════════════════════════════════════════╝")
            print("")
            print("📊 Toplam Declaration: \(result.totalDeclarations)")
            print("🔴 Kullanılmayan: \(result.unusedCount)")
            print("🟢 Kullanım Oranı: \(String(format: "%.1f", result.usagePercentage))%")
            print("📁 Dosya: \(result.analyzedFiles.count)")
            print("🎯 Entry Point: \(result.entryPoints.count)")
            print("")
        }
        
        private func applyDeletions(
            findings: [Finding],
            workingDir: String,
            config: NSClearConfig
        ) async throws {
            print("🔧 Değişiklikler uygulanıyor...")
            
            // Git kontrolü
            let git = GitOperations(workingDirectory: workingDir, config: config.git)
            
            if !git.isGitRepository() {
                print("⚠️  Git repository değil. Devam edilsin mi? (yes/no): ", terminator: "")
                guard let response = readLine()?.lowercased(), response == "yes" || response == "y" else {
                    print("❌ İşlem iptal edildi")
                    return
                }
            } else if git.hasUncommittedChanges() {
                print("⚠️  Commit edilmemiş değişiklikler var. Devam edilsin mi? (yes/no): ", terminator: "")
                guard let response = readLine()?.lowercased(), response == "yes" || response == "y" else {
                    print("❌ İşlem iptal edildi")
            return
                }
            }
            
            // Branch oluştur
            if git.isGitRepository() && config.git.autoCommit {
                let branchName = git.generateBranchName()
                try git.createBranch(name: branchName)
            }
            
            // Backup oluştur
            let rewriter = CodeRewriter()
            let filesToModify = Set(findings.map { $0.declaration.filePath })
            let backupDir = try rewriter.createBackup(for: Array(filesToModify))
            print("💾 Backup oluşturuldu: \(backupDir)")
            
            // Deletions uygula
            print("🔄 Dosyalar değiştiriliyor...")
            let modifiedFiles = try rewriter.applyDeletions(findings: findings)
            try rewriter.writeModifiedFiles(modifiedFiles)
            print("✅ \(modifiedFiles.count) dosya değiştirildi")
            
            // Test çalıştır
            if config.testing.runTests {
                print("🧪 Testler çalıştırılıyor...")
                let testsPassed = try await runTests(workingDir: workingDir, config: config)
                
                if !testsPassed {
                    print("❌ Testler başarısız! Değişiklikler geri alınıyor...")
                    try rewriter.restoreFromBackup(backupDir: backupDir, to: Array(filesToModify))
                    print("✅ Değişiklikler geri alındı")
                    throw NSError(domain: "NSClear", code: 4, userInfo: [
                        NSLocalizedDescriptionKey: "Testler başarısız oldu"
                    ])
                }
                print("✅ Testler başarılı!")
            }
            
            // Commit
            if git.isGitRepository() && config.git.autoCommit {
                try git.commitChanges(count: findings.count)
            }
            
            print("")
            print("🎉 İşlem tamamlandı! \(findings.count) declaration silindi.")
        }
        
        private func runTests(workingDir: String, config: NSClearConfig) async throws -> Bool {
            let process = Process()
            process.currentDirectoryURL = URL(fileURLWithPath: workingDir)
            
            // Test komutunu belirle
            if let xcodeCommand = config.testing.xcodebuildCommand {
                let components = xcodeCommand.components(separatedBy: " ")
                process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
                process.arguments = Array(components.dropFirst())
            } else {
                let components = config.testing.swiftTestCommand.components(separatedBy: " ")
                process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
                process.arguments = Array(components.dropFirst())
            }
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            try process.run()
            process.waitUntilExit()
            
            return process.terminationStatus == 0
        }
    }
}

// MARK: - Apply Command

extension NSClear {
    struct Apply: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Analiz sonuçlarını uygula (scan ile aynı ama apply varsayılan)"
        )
        
        @OptionGroup var scanOptions: Scan
        
        mutating func run() async throws {
            scanOptions.apply = true
            try await scanOptions.run()
        }
    }
}

// MARK: - Report Command

extension NSClear {
    struct Report: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Mevcut analiz sonuçlarını farklı formatlarda raporla"
        )
        
        @Argument(help: "Analiz sonucu JSON dosyası")
        var inputFile: String
        
        @Option(name: .long, help: "Çıktı formatı (text|markdown|xcode)")
        var format: String = "text"
        
        @Option(name: .long, help: "Çıktı dosyası")
        var output: String?
        
        func run() throws {
            let data = try Data(contentsOf: URL(fileURLWithPath: inputFile))
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let result = try decoder.decode(AnalysisResult.self, from: data)
            
            let reporter = Reporter(result: result)
            
            let reportContent: String
            switch format {
            case "markdown":
                reportContent = reporter.generateMarkdownReport()
            case "xcode":
                reportContent = reporter.generateXcodeDiagnostics()
        default:
                reportContent = reporter.generateTextReport()
            }
            
            if let output = output {
                try reportContent.write(toFile: output, atomically: true, encoding: .utf8)
                print("✅ Rapor yazıldı: \(output)")
            } else {
                print(reportContent)
            }
        }
    }
}
