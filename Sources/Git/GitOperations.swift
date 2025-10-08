import Foundation

/// Git operasyonlarını yöneten sınıf
final class GitOperations {
    private let workingDirectory: String
    private let config: GitConfig
    
    init(workingDirectory: String, config: GitConfig = GitConfig()) {
        self.workingDirectory = workingDirectory
        self.config = config
    }
    
    /// Yeni branch oluştur ve geçiş yap
    func createBranch(name: String) throws {
        let fullBranchName = "\(config.branchPrefix)/\(name)"
        
        // Mevcut değişiklikleri kontrol et
        if hasUncommittedChanges() {
            throw GitError.uncommittedChanges
        }
        
        // Branch oluştur
        try runGitCommand(["checkout", "-b", fullBranchName])
        
        print("✅ Branch oluşturuldu: \(fullBranchName)")
    }
    
    /// Otomatik branch ismi oluştur
    func generateBranchName() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        return "unused-code-\(timestamp)"
    }
    
    /// Değişiklikleri commit et
    func commit(message: String) throws {
        // Stage all changes
        try runGitCommand(["add", "-A"])
        
        // Commit
        try runGitCommand(["commit", "-m", message])
        
        print("✅ Commit yapıldı: \(message)")
    }
    
    /// Değişiklikleri commit et (otomatik mesaj)
    func commitChanges(count: Int) throws {
        let message = config.commitMessageFormat.replacingOccurrences(of: "{count}", with: "\(count)")
        try commit(message: message)
    }
    
    /// Değişiklikleri geri al
    func revertChanges() throws {
        try runGitCommand(["reset", "--hard", "HEAD"])
        print("✅ Değişiklikler geri alındı")
    }
    
    /// Working directory'yi temizle
    func clean() throws {
        try runGitCommand(["clean", "-fd"])
        print("✅ Working directory temizlendi")
    }
    
    /// Mevcut branch'i al
    func getCurrentBranch() throws -> String {
        let output = try runGitCommand(["branch", "--show-current"])
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Commit edilmemiş değişiklik var mı?
    func hasUncommittedChanges() -> Bool {
        do {
            let output = try runGitCommand(["status", "--porcelain"])
            return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } catch {
            return false
        }
    }
    
    /// Diff oluştur
    func getDiff() throws -> String {
        return try runGitCommand(["diff", "HEAD"])
    }
    
    /// Staged diff oluştur
    func getStagedDiff() throws -> String {
        return try runGitCommand(["diff", "--cached"])
    }
    
    /// Patch dosyası oluştur
    func createPatch(outputPath: String) throws {
        let diff = try getDiff()
        try diff.write(toFile: outputPath, atomically: true, encoding: .utf8)
        print("✅ Patch dosyası oluşturuldu: \(outputPath)")
    }
    
    /// Git repository olup olmadığını kontrol et
    func isGitRepository() -> Bool {
        let gitDir = workingDirectory + "/.git"
        return FileManager.default.fileExists(atPath: gitDir)
    }
    
    /// Git durumunu göster
    func status() throws -> String {
        return try runGitCommand(["status"])
    }
    
    // MARK: - Private Helpers
    
    @discardableResult
    private func runGitCommand(_ arguments: [String]) throws -> String {
        let process = Process()
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        let output = String(data: outputData, encoding: .utf8) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
        
        if process.terminationStatus != 0 {
            throw GitError.commandFailed(command: "git \(arguments.joined(separator: " "))", 
                                        output: errorOutput)
        }
        
        return output
    }
}

/// Git hataları
enum GitError: LocalizedError {
    case commandFailed(command: String, output: String)
    case uncommittedChanges
    case notARepository
    
    var errorDescription: String? {
        switch self {
        case .commandFailed(let command, let output):
            return "Git komutu başarısız oldu: \(command)\n\(output)"
        case .uncommittedChanges:
            return "Commit edilmemiş değişiklikler var. Lütfen önce bunları commit edin veya stash'leyin."
        case .notARepository:
            return "Bu dizin bir Git repository değil."
        }
    }
}

