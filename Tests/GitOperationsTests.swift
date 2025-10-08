import Testing
import Foundation
@testable import NSClear

/// GitOperations test suite
struct GitOperationsTests {
    
    @Test("Branch ismi oluşturma")
    func testGenerateBranchName() {
        let git = GitOperations(workingDirectory: "/tmp")
        let branchName = git.generateBranchName()
        
        #expect(branchName.hasPrefix("unused-code-"))
        #expect(branchName.count > 15) // timestamp içeriyor
    }
    
    @Test("Git error açıklamaları")
    func testGitErrorDescriptions() {
        let commandError = GitError.commandFailed(command: "git status", output: "error")
        #expect(commandError.errorDescription?.contains("Git komutu başarısız oldu") == true)
        
        let uncommittedError = GitError.uncommittedChanges
        #expect(uncommittedError.errorDescription?.contains("Commit edilmemiş değişiklikler") == true)
        
        let notRepoError = GitError.notARepository
        #expect(notRepoError.errorDescription?.contains("Git repository değil") == true)
    }
    
    @Test("Git config kullanımı")
    func testGitConfigUsage() {
        let customConfig = GitConfig()
        let git = GitOperations(workingDirectory: "/tmp", config: customConfig)
        
        let branchName = git.generateBranchName()
        #expect(branchName.contains("unused-code"))
    }
}

