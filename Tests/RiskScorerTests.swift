import Testing
import Foundation
@testable import NSClear

/// RiskScorer test suite
struct RiskScorerTests {
    
    @Test("Private declaration risk skoru")
    func testPrivateDeclarationRiskScore() {
        let config = RiskScoringConfig()
        let scorer = RiskScorer(config: config)
        
        let declaration = Declaration(
            kind: .function,
            name: "privateHelper",
            filePath: "/test.swift",
            line: 1,
            column: 1,
            byteOffset: 0,
            byteLength: 50, // Küçük helper
            accessLevel: .private
        )
        
        let score = scorer.calculateRiskScore(for: declaration, references: [])
        
        // Private ve küçük helper olduğu için düşük risk
        #expect(score <= 20)
    }
    
    @Test("Public API risk skoru")
    func testPublicAPIRiskScore() {
        let config = RiskScoringConfig()
        let scorer = RiskScorer(config: config)
        
        let declaration = Declaration(
            kind: .function,
            name: "publicAPI",
            filePath: "/test.swift",
            line: 1,
            column: 1,
            byteOffset: 0,
            byteLength: 100,
            accessLevel: .public
        )
        
        let score = scorer.calculateRiskScore(for: declaration, references: [])
        
        // Public API olduğu için yüksek risk
        #expect(score >= 80)
    }
    
    @Test("ObjC attribute risk skoru")
    func testObjCAttributeRiskScore() {
        let config = RiskScoringConfig()
        let scorer = RiskScorer(config: config)
        
        let declaration = Declaration(
            kind: .function,
            name: "objcFunction",
            filePath: "/test.swift",
            line: 1,
            column: 1,
            byteOffset: 0,
            byteLength: 100,
            accessLevel: .internal,
            attributes: ["@objc"]
        )
        
        let score = scorer.calculateRiskScore(for: declaration, references: [])
        
        // ObjC attribute olduğu için çok yüksek risk
        #expect(score >= 90)
    }
    
    @Test("Dynamic modifier risk skoru")
    func testDynamicModifierRiskScore() {
        let config = RiskScoringConfig()
        let scorer = RiskScorer(config: config)
        
        let declaration = Declaration(
            kind: .property,
            name: "dynamicProperty",
            filePath: "/test.swift",
            line: 1,
            column: 1,
            byteOffset: 0,
            byteLength: 50,
            accessLevel: .internal,
            modifiers: ["dynamic"]
        )
        
        let score = scorer.calculateRiskScore(for: declaration, references: [])
        
        // Dynamic modifier olduğu için çok yüksek risk
        #expect(score >= 90)
    }
    
    @Test("Referans varsa risk düşmeli")
    func testReferenceReducesRisk() {
        let config = RiskScoringConfig()
        let scorer = RiskScorer(config: config)
        
        let declaration = Declaration(
            kind: .function,
            name: "test",
            filePath: "/test.swift",
            line: 1,
            column: 1,
            byteOffset: 0,
            byteLength: 100,
            accessLevel: .public
        )
        
        let scoreWithoutRefs = scorer.calculateRiskScore(for: declaration, references: [])
        
        let references = [
            Reference(filePath: "/other.swift", line: 10, column: 5, context: "call")
        ]
        let scoreWithRefs = scorer.calculateRiskScore(for: declaration, references: references)
        
        // Referans varsa risk düşmeli
        #expect(scoreWithRefs < scoreWithoutRefs)
    }
    
    @Test("Protocol witness yüksek risk")
    func testProtocolWitnessRiskScore() {
        let config = RiskScoringConfig()
        let scorer = RiskScorer(config: config)
        
        let declaration = Declaration(
            kind: .function,
            name: "protocolMethod",
            filePath: "/test.swift",
            line: 1,
            column: 1,
            byteOffset: 0,
            byteLength: 100,
            accessLevel: .internal,
            isProtocolWitness: true
        )
        
        let score = scorer.calculateRiskScore(for: declaration, references: [])
        
        // Protocol witness olduğu için yüksek risk
        #expect(score >= 80)
    }
}

