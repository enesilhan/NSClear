import Foundation

/// Basit regex-based syntax analyzer (SwiftParser olmadan)
/// Import sorunlarını bypass eder, sadece temel declaration'ları bulur
final class SimpleSyntaxAnalyzer {
    private let config: NSClearConfig
    
    init(config: NSClearConfig = NSClearConfig()) {
        self.config = config
    }
    
    /// Dosyadaki declaration'ları basit regex ile bul
    func analyzeFile(at path: String) -> [Declaration] {
        guard let source = try? String(contentsOfFile: path) else {
            return []
        }
        
        var declarations: [Declaration] = []
        let lines = source.components(separatedBy: .newlines)
        
        for (lineIndex, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip comments and imports
            if trimmed.hasPrefix("//") || trimmed.hasPrefix("import ") || trimmed.isEmpty {
                continue
            }
            
            // Class
            if let classDecl = parseClass(line: trimmed, lineNumber: lineIndex + 1, filePath: path) {
                declarations.append(classDecl)
            }
            
            // Struct
            if let structDecl = parseStruct(line: trimmed, lineNumber: lineIndex + 1, filePath: path) {
                declarations.append(structDecl)
            }
            
            // Enum
            if let enumDecl = parseEnum(line: trimmed, lineNumber: lineIndex + 1, filePath: path) {
                declarations.append(enumDecl)
            }
            
            // Protocol
            if let protocolDecl = parseProtocol(line: trimmed, lineNumber: lineIndex + 1, filePath: path) {
                declarations.append(protocolDecl)
            }
            
            // Function
            if let funcDecl = parseFunction(line: trimmed, lineNumber: lineIndex + 1, filePath: path) {
                declarations.append(funcDecl)
            }
            
            // Property/Variable
            if let varDecl = parseVariable(line: trimmed, lineNumber: lineIndex + 1, filePath: path) {
                declarations.append(varDecl)
            }
        }
        
        return declarations
    }
    
    // MARK: - Parsers
    
    private func parseClass(line: String, lineNumber: Int, filePath: String) -> Declaration? {
        let pattern = #"(public |private |internal |fileprivate |open )?(final )?class\s+(\w+)"#
        guard let className = extractName(from: line, pattern: pattern) else { return nil }
        
        let matched = String(line.range(of: pattern, options: .regularExpression).map { line[$0] } ?? "")
        let components = matched.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        let accessLevel = extractAccessLevel(from: components)
        let attributes = extractAttributes(from: line)
        
        return Declaration(
            kind: .class,
            name: className,
            filePath: filePath,
            line: lineNumber,
            column: 1,
            byteOffset: 0,
            byteLength: line.count,
            accessLevel: accessLevel,
            attributes: attributes
        )
    }
    
    private func parseStruct(line: String, lineNumber: Int, filePath: String) -> Declaration? {
        let pattern = #"(public |private |internal |fileprivate )?(struct)\s+(\w+)"#
        guard let structName = extractName(from: line, pattern: pattern) else { return nil }
        
        let matched = String(line.range(of: pattern, options: .regularExpression).map { line[$0] } ?? "")
        let components = matched.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        let accessLevel = extractAccessLevel(from: components)
        let attributes = extractAttributes(from: line)
        
        return Declaration(
            kind: .struct,
            name: structName,
            filePath: filePath,
            line: lineNumber,
            column: 1,
            byteOffset: 0,
            byteLength: line.count,
            accessLevel: accessLevel,
            attributes: attributes
        )
    }
    
    private func parseEnum(line: String, lineNumber: Int, filePath: String) -> Declaration? {
        let pattern = #"(public |private |internal |fileprivate )?(enum)\s+(\w+)"#
        guard let enumName = extractName(from: line, pattern: pattern) else { return nil }
        
        let matched = String(line.range(of: pattern, options: .regularExpression).map { line[$0] } ?? "")
        let components = matched.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        let accessLevel = extractAccessLevel(from: components)
        let attributes = extractAttributes(from: line)
        
        return Declaration(
            kind: .enum,
            name: enumName,
            filePath: filePath,
            line: lineNumber,
            column: 1,
            byteOffset: 0,
            byteLength: line.count,
            accessLevel: accessLevel,
            attributes: attributes
        )
    }
    
    private func parseProtocol(line: String, lineNumber: Int, filePath: String) -> Declaration? {
        let pattern = #"(public |private |internal )?(protocol)\s+(\w+)"#
        guard let protocolName = extractName(from: line, pattern: pattern) else { return nil }
        
        let matched = String(line.range(of: pattern, options: .regularExpression).map { line[$0] } ?? "")
        let components = matched.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        let accessLevel = extractAccessLevel(from: components)
        let attributes = extractAttributes(from: line)
        
        return Declaration(
            kind: .protocol,
            name: protocolName,
            filePath: filePath,
            line: lineNumber,
            column: 1,
            byteOffset: 0,
            byteLength: line.count,
            accessLevel: accessLevel,
            attributes: attributes
        )
    }
    
    private func parseFunction(line: String, lineNumber: Int, filePath: String) -> Declaration? {
        let pattern = #"(public |private |internal |fileprivate |@\w+ )*(func)\s+(\w+)"#
        guard let funcName = extractName(from: line, pattern: pattern) else { return nil }
        
        let matched = String(line.range(of: pattern, options: .regularExpression).map { line[$0] } ?? "")
        let components = matched.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        let accessLevel = extractAccessLevel(from: components)
        let attributes = extractAttributes(from: line)
        
        return Declaration(
            kind: .function,
            name: funcName,
            filePath: filePath,
            line: lineNumber,
            column: 1,
            byteOffset: 0,
            byteLength: line.count,
            accessLevel: accessLevel,
            attributes: attributes
        )
    }
    
    private func parseVariable(line: String, lineNumber: Int, filePath: String) -> Declaration? {
        let pattern = #"(public |private |internal |fileprivate |@\w+ )*(var|let)\s+(\w+)"#
        guard let varName = extractName(from: line, pattern: pattern) else { return nil }
        
        let matched = String(line.range(of: pattern, options: .regularExpression).map { line[$0] } ?? "")
        let components = matched.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        let accessLevel = extractAccessLevel(from: components)
        let attributes = extractAttributes(from: line)
        let isConstant = components.contains("let")
        
        return Declaration(
            kind: isConstant ? .constant : .property,
            name: varName,
            filePath: filePath,
            line: lineNumber,
            column: 1,
            byteOffset: 0,
            byteLength: line.count,
            accessLevel: accessLevel,
            attributes: attributes
        )
    }
    
    // MARK: - Helpers
    
    /// Extract name from regex capture group (avoids issues with components.last)
    private func extractName(from line: String, pattern: String, captureGroupIndex: Int = 3) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              match.numberOfRanges > captureGroupIndex else { return nil }
        
        let nameRange = match.range(at: captureGroupIndex)
        guard let swiftRange = Range(nameRange, in: line) else { return nil }
        return String(line[swiftRange])
    }
    
    private func extractAccessLevel(from components: [String]) -> AccessLevel {
        if components.contains("private") { return .private }
        if components.contains("fileprivate") { return .fileprivate }
        if components.contains("public") { return .public }
        if components.contains("open") { return .open }
        return .internal
    }
    
    private func extractAttributes(from line: String) -> [String] {
        var attributes: [String] = []
        
        // @objc, @IBAction, etc.
        let attrPattern = #"@\w+"#
        if let regex = try? NSRegularExpression(pattern: attrPattern) {
            let range = NSRange(line.startIndex..., in: line)
            let matches = regex.matches(in: line, range: range)
            
            for match in matches {
                if let range = Range(match.range, in: line) {
                    attributes.append(String(line[range]))
                }
            }
        }
        
        return attributes
    }
}

