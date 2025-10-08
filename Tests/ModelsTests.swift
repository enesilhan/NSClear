import Testing
import Foundation
@testable import NSClear

/// Models test suite
struct ModelsTests {
    
    @Test("Declaration oluşturma")
    func testDeclarationCreation() {
        let declaration = Declaration(
            kind: .function,
            name: "testFunction",
            filePath: "/path/to/file.swift",
            line: 10,
            column: 5,
            byteOffset: 100,
            byteLength: 50,
            accessLevel: .private
        )
        
        #expect(declaration.kind == .function)
        #expect(declaration.name == "testFunction")
        #expect(declaration.accessLevel == .private)
    }
    
    @Test("Declaration korumalı attribute kontrolü")
    func testDeclarationProtectedAttributes() {
        let objcDeclaration = Declaration(
            kind: .function,
            name: "objcFunction",
            filePath: "/path/to/file.swift",
            line: 10,
            column: 5,
            byteOffset: 100,
            byteLength: 50,
            accessLevel: .public,
            attributes: ["@objc"]
        )
        
        #expect(objcDeclaration.hasProtectedAttributes())
        
        let normalDeclaration = Declaration(
            kind: .function,
            name: "normalFunction",
            filePath: "/path/to/file.swift",
            line: 10,
            column: 5,
            byteOffset: 100,
            byteLength: 50,
            accessLevel: .private
        )
        
        #expect(!normalDeclaration.hasProtectedAttributes())
    }
    
    @Test("Declaration korumalı modifier kontrolü")
    func testDeclarationProtectedModifiers() {
        let dynamicDeclaration = Declaration(
            kind: .property,
            name: "dynamicProperty",
            filePath: "/path/to/file.swift",
            line: 10,
            column: 5,
            byteOffset: 100,
            byteLength: 50,
            accessLevel: .public,
            modifiers: ["dynamic"]
        )
        
        #expect(dynamicDeclaration.hasProtectedModifiers())
    }
    
    @Test("Finding risk level hesaplama")
    func testFindingRiskLevel() {
        let declaration = Declaration(
            kind: .function,
            name: "test",
            filePath: "/test.swift",
            line: 1,
            column: 1,
            byteOffset: 0,
            byteLength: 10,
            accessLevel: .private
        )
        
        let lowRiskFinding = Finding(
            declaration: declaration,
            reason: "Unused",
            riskScore: 10
        )
        #expect(lowRiskFinding.riskLevel == .low)
        
        let mediumRiskFinding = Finding(
            declaration: declaration,
            reason: "Unused",
            riskScore: 30
        )
        #expect(mediumRiskFinding.riskLevel == .medium)
        
        let highRiskFinding = Finding(
            declaration: declaration,
            reason: "Unused",
            riskScore: 60
        )
        #expect(highRiskFinding.riskLevel == .high)
        
        let veryHighRiskFinding = Finding(
            declaration: declaration,
            reason: "Unused",
            riskScore: 90
        )
        #expect(veryHighRiskFinding.riskLevel == .veryHigh)
    }
    
    @Test("Access level risk multiplier")
    func testAccessLevelRiskMultiplier() {
        #expect(AccessLevel.private.riskMultiplier == 1.0)
        #expect(AccessLevel.fileprivate.riskMultiplier == 1.2)
        #expect(AccessLevel.internal.riskMultiplier == 1.5)
        #expect(AccessLevel.public.riskMultiplier == 2.0)
        #expect(AccessLevel.open.riskMultiplier == 2.5)
    }
    
    @Test("AnalysisResult kullanım yüzdesi hesaplama")
    func testAnalysisResultUsagePercentage() {
        let declaration = Declaration(
            kind: .function,
            name: "test",
            filePath: "/test.swift",
            line: 1,
            column: 1,
            byteOffset: 0,
            byteLength: 10,
            accessLevel: .private
        )
        
        let findings = [
            Finding(declaration: declaration, reason: "Unused", riskScore: 10),
            Finding(declaration: declaration, reason: "Unused", riskScore: 20)
        ]
        
        let result = AnalysisResult(
            findings: findings,
            totalDeclarations: 10,
            analyzedFiles: [],
            entryPoints: []
        )
        
        #expect(result.unusedCount == 2)
        #expect(result.usagePercentage == 80.0)
    }
}

