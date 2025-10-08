import Testing
import Foundation
@testable import NSClear

/// Configuration test suite
struct ConfigTests {
    
    @Test("Varsayılan konfigürasyon oluşturma")
    func testDefaultConfiguration() {
        let config = NSClearConfig()
        
        #expect(config.checkPublicAPI == false)
        #expect(config.maxAutoSelectRisk == 20)
        #expect(config.exclude.contains("**/Tests/**"))
        #expect(config.entryPoints.detectMain == true)
        #expect(config.protections.protectObjC == true)
        #expect(config.testing.runTests == true)
        #expect(config.git.autoCommit == true)
    }
    
    @Test("Entry points configuration")
    func testEntryPointsConfiguration() {
        let config = EntryPointsConfig()
        
        #expect(config.detectMain == true)
        #expect(config.detectSwiftUIApp == true)
        #expect(config.detectUIApplicationMain == true)
        #expect(config.includePublicAPI == true)
        #expect(config.includeObjCSymbols == true)
        #expect(config.includeTestEntryPoints == true)
        #expect(config.customPatterns.isEmpty)
    }
    
    @Test("Risk scoring configuration")
    func testRiskScoringConfiguration() {
        let config = RiskScoringConfig()
        
        #expect(config.publicAPIWeight == 90)
        #expect(config.objcDynamicWeight == 95)
        #expect(config.protocolWitnessWeight == 85)
        #expect(config.selectorPresenceWeight == 80)
        #expect(config.testOnlyWeight == 40)
        #expect(config.privateHelperWeight == 10)
    }
    
    @Test("Protections configuration")
    func testProtectionsConfiguration() {
        let config = ProtectionsConfig()
        
        #expect(config.protectObjC == true)
        #expect(config.protectDynamic == true)
        #expect(config.protectIB == true)
        #expect(config.protectNSManaged == true)
        #expect(config.protectInlinable == true)
        #expect(config.protectCDecl == true)
        #expect(config.protectSPI == true)
        #expect(config.protectPreviews == true)
        #expect(config.protectExtensions == true)
        #expect(config.protectStoryboardSelectors == true)
    }
    
    @Test("Testing configuration")
    func testTestingConfiguration() {
        let config = TestingConfig()
        
        #expect(config.runTests == true)
        #expect(config.xcodebuildCommand == nil)
        #expect(config.swiftTestCommand == "swift test")
        #expect(config.timeout == 300)
    }
    
    @Test("Git configuration")
    func testGitConfiguration() {
        let config = GitConfig()
        
        #expect(config.autoCommit == true)
        #expect(config.branchPrefix == "nsclear")
        #expect(config.commitMessageFormat == "chore: clear unused code ({count} declarations)")
    }
}

