import Testing
import Foundation
@testable import NSClear

/// Reporter test suite
struct ReporterTests {
    
    func createTestResult() -> AnalysisResult {
        let declaration1 = Declaration(
            kind: .function,
            name: "unusedFunction1",
            filePath: "/path/to/file1.swift",
            line: 10,
            column: 5,
            byteOffset: 100,
            byteLength: 50,
            accessLevel: .private
        )
        
        let declaration2 = Declaration(
            kind: .class,
            name: "UnusedClass",
            filePath: "/path/to/file2.swift",
            line: 20,
            column: 1,
            byteOffset: 200,
            byteLength: 100,
            accessLevel: .public
        )
        
        let findings = [
            Finding(declaration: declaration1, reason: "Not referenced", riskScore: 15),
            Finding(declaration: declaration2, reason: "Not reachable", riskScore: 85)
        ]
        
        return AnalysisResult(
            findings: findings,
            totalDeclarations: 100,
            analyzedFiles: ["/path/to/file1.swift", "/path/to/file2.swift"],
            entryPoints: []
        )
    }
    
    @Test("JSON raporu oluşturma")
    func testGenerateJSONReport() throws {
        let result = createTestResult()
        let reporter = Reporter(result: result)
        
        let json = try reporter.generateJSONReport()
        
        #expect(json.contains("\"totalDeclarations\" : 100"))
        #expect(json.contains("\"unusedFunction1\""))
        #expect(json.contains("\"UnusedClass\""))
    }
    
    @Test("Text raporu oluşturma")
    func testGenerateTextReport() {
        let result = createTestResult()
        let reporter = Reporter(result: result)
        
        let text = reporter.generateTextReport()
        
        #expect(text.contains("NSClear - Analiz Raporu"))
        #expect(text.contains("Toplam Declaration: 100"))
        #expect(text.contains("Kullanılmayan: 2"))
        #expect(text.contains("unusedFunction1"))
        #expect(text.contains("UnusedClass"))
    }
    
    @Test("Markdown raporu oluşturma")
    func testGenerateMarkdownReport() {
        let result = createTestResult()
        let reporter = Reporter(result: result)
        
        let markdown = reporter.generateMarkdownReport()
        
        #expect(markdown.contains("# NSClear - Analiz Raporu"))
        #expect(markdown.contains("## 📊 Özet"))
        #expect(markdown.contains("| Toplam Declaration | 100 |"))
        #expect(markdown.contains("`unusedFunction1`"))
    }
    
    @Test("Xcode diagnostics oluşturma")
    func testGenerateXcodeDiagnostics() {
        let result = createTestResult()
        let reporter = Reporter(result: result)
        
        let diagnostics = reporter.generateXcodeDiagnostics()
        
        #expect(diagnostics.contains("/path/to/file1.swift:10:5:"))
        #expect(diagnostics.contains("note: [NSClear]"))
        #expect(diagnostics.contains("unusedFunction1"))
    }
    
    @Test("Rapor format enum")
    func testReportFormat() {
        #expect(ReportFormat.json.rawValue == "json")
        #expect(ReportFormat.text.rawValue == "text")
        #expect(ReportFormat.xcode.rawValue == "xcode")
        #expect(ReportFormat.markdown.rawValue == "markdown")
        
        #expect(ReportFormat.allCases.count == 4)
    }
}

