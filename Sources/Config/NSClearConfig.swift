import Foundation
import Yams

/// NSClear konfigürasyon yapısı (.nsclear.yml)
struct NSClearConfig: Codable {
    /// Analiz edilecek hedefler
    var targets: [String]?
    
    /// Hariç tutulacak dosya/klasör pattern'leri
    var exclude: [String]
    
    /// Entry point olarak kabul edilecek attributeler
    var entryPoints: EntryPointsConfig
    
    /// Risk skorlama yapılandırması
    var riskScoring: RiskScoringConfig
    
    /// Koruma kuralları
    var protections: ProtectionsConfig
    
    /// Public API kontrolü
    var checkPublicAPI: Bool
    
    /// Otomatik seçim için maksimum risk skoru
    var maxAutoSelectRisk: Int
    
    /// Test çalıştırma ayarları
    var testing: TestingConfig
    
    /// Git yapılandırması
    var git: GitConfig
    
    init() {
        self.targets = nil
        self.exclude = [
            "**/Tests/**",
            "**/*Tests.swift",
            "**/.build/**",
            "**/DerivedData/**"
        ]
        self.entryPoints = EntryPointsConfig()
        self.riskScoring = RiskScoringConfig()
        self.protections = ProtectionsConfig()
        self.checkPublicAPI = false
        self.maxAutoSelectRisk = 20
        self.testing = TestingConfig()
        self.git = GitConfig()
    }
    
    /// YAML dosyasından konfigürasyonu yükle
    static func load(from path: String) throws -> NSClearConfig {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let decoder = YAMLDecoder()
        return try decoder.decode(NSClearConfig.self, from: data)
    }
    
    /// Varsayılan konfigürasyon dosyası oluştur
    static func createDefault(at path: String) throws {
        let config = NSClearConfig()
        let encoder = YAMLEncoder()
        let yaml = try encoder.encode(config)
        try yaml.write(toFile: path, atomically: true, encoding: .utf8)
    }
}

/// Entry point yapılandırması
struct EntryPointsConfig: Codable {
    /// @main attribute'unu entry point olarak kabul et
    var detectMain: Bool
    
    /// SwiftUI.App türlerini entry point olarak kabul et
    var detectSwiftUIApp: Bool
    
    /// UIApplicationMain'i entry point olarak kabul et
    var detectUIApplicationMain: Bool
    
    /// Public/open API'yi entry point olarak kabul et
    var includePublicAPI: Bool
    
    /// @objc/dynamic sembolleri entry point olarak kabul et
    var includeObjCSymbols: Bool
    
    /// Test entry point'lerini dahil et
    var includeTestEntryPoints: Bool
    
    /// Özel entry point pattern'leri (regex)
    var customPatterns: [String]
    
    init() {
        self.detectMain = true
        self.detectSwiftUIApp = true
        self.detectUIApplicationMain = true
        self.includePublicAPI = true
        self.includeObjCSymbols = true
        self.includeTestEntryPoints = true
        self.customPatterns = []
    }
}

/// Risk skorlama yapılandırması
struct RiskScoringConfig: Codable {
    /// Public/open declaration riski
    var publicAPIWeight: Int
    
    /// @objc/dynamic riski
    var objcDynamicWeight: Int
    
    /// Protocol/witness riski
    var protocolWitnessWeight: Int
    
    /// Selector string varlığı riski
    var selectorPresenceWeight: Int
    
    /// Test-only kod riski
    var testOnlyWeight: Int
    
    /// Private helper riski (düşük)
    var privateHelperWeight: Int
    
    init() {
        self.publicAPIWeight = 90
        self.objcDynamicWeight = 95
        self.protocolWitnessWeight = 85
        self.selectorPresenceWeight = 80
        self.testOnlyWeight = 40
        self.privateHelperWeight = 10
    }
}

/// Koruma kuralları yapılandırması
struct ProtectionsConfig: Codable {
    /// @objc işaretli declaration'ları koru
    var protectObjC: Bool
    
    /// dynamic işaretli declaration'ları koru
    var protectDynamic: Bool
    
    /// @IBAction/@IBOutlet işaretli declaration'ları koru
    var protectIB: Bool
    
    /// @NSManaged işaretli declaration'ları koru
    var protectNSManaged: Bool
    
    /// @inlinable/@usableFromInline işaretli declaration'ları koru
    var protectInlinable: Bool
    
    /// @_cdecl işaretli declaration'ları koru
    var protectCDecl: Bool
    
    /// @_spi işaretli declaration'ları koru
    var protectSPI: Bool
    
    /// SwiftUI Preview'ları koru
    var protectPreviews: Bool
    
    /// Widget/Intent/Live Activity kodunu koru
    var protectExtensions: Bool
    
    /// Storyboard/XIB selector'larını koru
    var protectStoryboardSelectors: Bool
    
    init() {
        self.protectObjC = true
        self.protectDynamic = true
        self.protectIB = true
        self.protectNSManaged = true
        self.protectInlinable = true
        self.protectCDecl = true
        self.protectSPI = true
        self.protectPreviews = true
        self.protectExtensions = true
        self.protectStoryboardSelectors = true
    }
}

/// Test yapılandırması
struct TestingConfig: Codable {
    /// Değişiklik sonrası test çalıştır
    var runTests: Bool
    
    /// Xcode build komutu
    var xcodebuildCommand: String?
    
    /// SwiftPM test komutu
    var swiftTestCommand: String
    
    /// Test timeout (saniye)
    var timeout: Int
    
    init() {
        self.runTests = true
        self.xcodebuildCommand = nil // Auto-detect
        self.swiftTestCommand = "swift test"
        self.timeout = 300 // 5 dakika
    }
}

/// Git yapılandırması
struct GitConfig: Codable {
    /// Değişiklikleri otomatik commit et
    var autoCommit: Bool
    
    /// Branch prefix
    var branchPrefix: String
    
    /// Commit mesaj formatı
    var commitMessageFormat: String
    
    init() {
        self.autoCommit = true
        self.branchPrefix = "nsclear"
        self.commitMessageFormat = "chore: clear unused code ({count} declarations)"
    }
}

