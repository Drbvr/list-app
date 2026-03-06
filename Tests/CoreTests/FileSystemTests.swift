import Foundation
import XCTest

#if canImport(Core)
import Core
#endif

final class FileSystemTests: XCTestCase {

    var tempDir: URL!
    var fileManager: DefaultFileSystemManager!

    override func setUp() {
        super.setUp()
        fileManager = DefaultFileSystemManager()

        // Create temporary directory
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ListAppTests-\(UUID().uuidString)")

        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        // Clean up temporary directory
        if let tempDir = tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
        super.tearDown()
    }

    // MARK: - Read File Tests

    func testReadSimpleFile() {
        let testFile = tempDir.appendingPathComponent("test.md")
        let content = "# Test\nThis is a test file"

        try? content.write(to: testFile, atomically: true, encoding: .utf8)

        let result = fileManager.readFile(at: testFile.path)

        guard case .success(let read) = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssertEqual(read, content)
    }

    func testReadNonExistentFile() {
        let nonExistent = tempDir.appendingPathComponent("nonexistent.md")

        let result = fileManager.readFile(at: nonExistent.path)

        guard case .failure(let error) = result else {
            XCTFail("Expected failure")
            return
        }

        if case .notFound = error {
            XCTAssert(true)
        } else {
            XCTFail("Expected notFound error")
        }
    }

    func testReadEmptyFile() {
        let emptyFile = tempDir.appendingPathComponent("empty.md")
        try? "".write(to: emptyFile, atomically: true, encoding: .utf8)

        let result = fileManager.readFile(at: emptyFile.path)

        guard case .success(let content) = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssertEqual(content, "")
    }

    func testReadFileWithSpecialCharacters() {
        let specialFile = tempDir.appendingPathComponent("special-áéíóú.md")
        let content = "# Special\nÁÉÍÓÚ áéíóú"

        try? content.write(to: specialFile, atomically: true, encoding: .utf8)

        let result = fileManager.readFile(at: specialFile.path)

        guard case .success(let read) = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssertEqual(read, content)
    }

    func testReadEmptyPath() {
        let result = fileManager.readFile(at: "")

        guard case .failure(let error) = result else {
            XCTFail("Expected failure")
            return
        }

        if case .invalidPath = error {
            XCTAssert(true)
        } else {
            XCTFail("Expected invalidPath error")
        }
    }

    // MARK: - Write File Tests

    func testWriteNewFile() {
        let newFile = tempDir.appendingPathComponent("new.md")
        let content = "# New File\nContent here"

        let result = fileManager.writeFile(at: newFile.path, content: content)

        guard case .success = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssert(FileManager.default.fileExists(atPath: newFile.path))

        let read = try? String(contentsOf: newFile, encoding: .utf8)
        XCTAssertEqual(read, content)
    }

    func testWriteFileWithNestedDirectories() {
        let nestedFile = tempDir.appendingPathComponent("a/b/c/file.md")
        let content = "Nested content"

        let result = fileManager.writeFile(at: nestedFile.path, content: content)

        guard case .success = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssert(FileManager.default.fileExists(atPath: nestedFile.path))

        let read = try? String(contentsOf: nestedFile, encoding: .utf8)
        XCTAssertEqual(read, content)
    }

    func testOverwriteExistingFile() {
        let file = tempDir.appendingPathComponent("overwrite.md")
        let originalContent = "Original"
        let newContent = "Updated"

        try? originalContent.write(to: file, atomically: true, encoding: .utf8)

        let result = fileManager.writeFile(at: file.path, content: newContent)

        guard case .success = result else {
            XCTFail("Expected success")
            return
        }

        let read = try? String(contentsOf: file, encoding: .utf8)
        XCTAssertEqual(read, newContent)
    }

    func testWriteEmptyContent() {
        let file = tempDir.appendingPathComponent("empty-write.md")

        let result = fileManager.writeFile(at: file.path, content: "")

        guard case .success = result else {
            XCTFail("Expected success")
            return
        }

        let read = try? String(contentsOf: file, encoding: .utf8)
        XCTAssertEqual(read, "")
    }

    func testWriteEmptyPath() {
        let result = fileManager.writeFile(at: "", content: "test")

        guard case .failure(let error) = result else {
            XCTFail("Expected failure")
            return
        }

        if case .invalidPath = error {
            XCTAssert(true)
        } else {
            XCTFail("Expected invalidPath error")
        }
    }

    // MARK: - Scan Directory Tests

    func testScanEmptyDirectory() {
        let emptyDir = tempDir.appendingPathComponent("empty")
        try? FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)

        let result = fileManager.scanDirectory(at: emptyDir.path, recursive: true)

        guard case .success(let files) = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssertEqual(files.count, 0)
    }

    func testScanDirectoryWithMarkdownFiles() {
        let subdir = tempDir.appendingPathComponent("docs")
        try? FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)

        let file1 = subdir.appendingPathComponent("test1.md")
        let file2 = subdir.appendingPathComponent("test2.md")
        let file3 = subdir.appendingPathComponent("test.txt")

        try? "content1".write(to: file1, atomically: true, encoding: .utf8)
        try? "content2".write(to: file2, atomically: true, encoding: .utf8)
        try? "not markdown".write(to: file3, atomically: true, encoding: .utf8)

        let result = fileManager.scanDirectory(at: subdir.path, recursive: false)

        guard case .success(let files) = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssertEqual(files.count, 2)
        XCTAssert(files.map { $0.hasSuffix(".md") }.allSatisfy { $0 })
    }

    func testScanDirectoryRecursive() {
        let subdir1 = tempDir.appendingPathComponent("level1")
        let subdir2 = subdir1.appendingPathComponent("level2")

        try? FileManager.default.createDirectory(at: subdir2, withIntermediateDirectories: true)

        let file1 = subdir1.appendingPathComponent("file1.md")
        let file2 = subdir2.appendingPathComponent("file2.md")

        try? "content1".write(to: file1, atomically: true, encoding: .utf8)
        try? "content2".write(to: file2, atomically: true, encoding: .utf8)

        let result = fileManager.scanDirectory(at: subdir1.path, recursive: true)

        guard case .success(let files) = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssertEqual(files.count, 2)
    }

    func testScanDirectoryExcludesHiddenFiles() {
        let docsDir = tempDir.appendingPathComponent("docs")
        try? FileManager.default.createDirectory(at: docsDir, withIntermediateDirectories: true)

        let visible = docsDir.appendingPathComponent("visible.md")
        let hidden = docsDir.appendingPathComponent(".hidden.md")

        try? "visible".write(to: visible, atomically: true, encoding: .utf8)
        try? "hidden".write(to: hidden, atomically: true, encoding: .utf8)

        let result = fileManager.scanDirectory(at: docsDir.path, recursive: false)

        guard case .success(let files) = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssertEqual(files.count, 1)
        XCTAssert(files[0].hasSuffix("visible.md"))
    }

    func testScanDirectoryExcludesSpecialFolders() {
        let rootDir = tempDir.appendingPathComponent("root")
        let gitDir = rootDir.appendingPathComponent(".git")
        let obsidianDir = rootDir.appendingPathComponent(".obsidian")
        let normalDir = rootDir.appendingPathComponent("normal")

        try? FileManager.default.createDirectory(at: gitDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: obsidianDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: normalDir, withIntermediateDirectories: true)

        let file1 = rootDir.appendingPathComponent("root.md")
        let file2 = gitDir.appendingPathComponent("git.md")
        let file3 = obsidianDir.appendingPathComponent("obsidian.md")
        let file4 = normalDir.appendingPathComponent("normal.md")

        try? "root".write(to: file1, atomically: true, encoding: .utf8)
        try? "git".write(to: file2, atomically: true, encoding: .utf8)
        try? "obsidian".write(to: file3, atomically: true, encoding: .utf8)
        try? "normal".write(to: file4, atomically: true, encoding: .utf8)

        let result = fileManager.scanDirectory(at: rootDir.path, recursive: true)

        guard case .success(let files) = result else {
            XCTFail("Expected success")
            return
        }

        // Should find root.md and normal/normal.md, but not files in .git or .obsidian
        XCTAssertEqual(files.count, 2)
    }

    func testScanNonExistentDirectory() {
        let nonExistent = tempDir.appendingPathComponent("nonexistent")

        let result = fileManager.scanDirectory(at: nonExistent.path, recursive: true)

        guard case .failure(let error) = result else {
            XCTFail("Expected failure")
            return
        }

        if case .notFound = error {
            XCTAssert(true)
        } else {
            XCTFail("Expected notFound error")
        }
    }

    // MARK: - List Subdirectories Tests

    func testListSubdirectories() {
        let parentDir = tempDir.appendingPathComponent("parent")
        let sub1 = parentDir.appendingPathComponent("sub1")
        let sub2 = parentDir.appendingPathComponent("sub2")
        let hidden = parentDir.appendingPathComponent(".hidden")

        try? FileManager.default.createDirectory(at: sub1, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: sub2, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: hidden, withIntermediateDirectories: true)

        let result = fileManager.listSubdirectories(at: parentDir.path)

        guard case .success(let subdirs) = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssertEqual(subdirs.count, 2)
        XCTAssert(subdirs.contains("sub1"))
        XCTAssert(subdirs.contains("sub2"))
        XCTAssert(!subdirs.contains(".hidden"))
    }

    func testListSubdirectoriesEmpty() {
        let emptyDir = tempDir.appendingPathComponent("empty")
        try? FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)

        let result = fileManager.listSubdirectories(at: emptyDir.path)

        guard case .success(let subdirs) = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssertEqual(subdirs.count, 0)
    }

    // MARK: - FileScanner Tests

    func testFileScannerScanForMarkdown() {
        let vaultDir = tempDir.appendingPathComponent("vault")
        try? FileManager.default.createDirectory(at: vaultDir, withIntermediateDirectories: true)

        let file1 = vaultDir.appendingPathComponent("note1.md")
        let file2 = vaultDir.appendingPathComponent("note2.md")

        try? "# Note 1".write(to: file1, atomically: true, encoding: .utf8)
        try? "# Note 2".write(to: file2, atomically: true, encoding: .utf8)

        let scanner = FileScanner()
        let result = scanner.scanForMarkdown(in: [vaultDir.path])

        guard case .success(let markdownFiles) = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssertEqual(markdownFiles.count, 2)
        XCTAssert(markdownFiles.allSatisfy { !$0.content.isEmpty })
    }

    func testFileScannerWithMultipleFolders() {
        let vault1 = tempDir.appendingPathComponent("vault1")
        let vault2 = tempDir.appendingPathComponent("vault2")

        try? FileManager.default.createDirectory(at: vault1, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: vault2, withIntermediateDirectories: true)

        let file1 = vault1.appendingPathComponent("note1.md")
        let file2 = vault2.appendingPathComponent("note2.md")

        try? "# Note 1".write(to: file1, atomically: true, encoding: .utf8)
        try? "# Note 2".write(to: file2, atomically: true, encoding: .utf8)

        let scanner = FileScanner()
        let result = scanner.scanForMarkdown(in: [vault1.path, vault2.path])

        guard case .success(let markdownFiles) = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssertEqual(markdownFiles.count, 2)
    }

    // MARK: - MarkdownFile Tests

    func testMarkdownFileEquality() {
        let date1 = Date()
        let date2 = date1.addingTimeInterval(10)

        let file1 = MarkdownFile(path: "/path/test.md", content: "test", modifiedAt: date1, folder: "folder")
        let file2 = MarkdownFile(path: "/path/test.md", content: "test", modifiedAt: date1, folder: "folder")
        let file3 = MarkdownFile(path: "/path/test.md", content: "test", modifiedAt: date2, folder: "folder")

        XCTAssertEqual(file1, file2)
        XCTAssertNotEqual(file1, file3)
    }

    // MARK: - Edge Cases

    func testReadFileInDirectory() {
        let file = tempDir.appendingPathComponent("test.txt")
        try? FileManager.default.createDirectory(at: file, withIntermediateDirectories: true)

        let result = fileManager.readFile(at: file.path)

        guard case .failure(let error) = result else {
            XCTFail("Expected failure")
            return
        }

        if case .invalidPath = error {
            XCTAssert(true)
        } else {
            XCTFail("Expected invalidPath error")
        }
    }

    func testPerformanceScanLargeDirectory() {
        let largeDir = tempDir.appendingPathComponent("large")
        try? FileManager.default.createDirectory(at: largeDir, withIntermediateDirectories: true)

        // Create 100 markdown files
        for i in 0..<100 {
            let file = largeDir.appendingPathComponent("file\(i).md")
            try? "Content \(i)".write(to: file, atomically: true, encoding: .utf8)
        }

        let startTime = Date()
        let result = fileManager.scanDirectory(at: largeDir.path, recursive: true)
        let elapsed = Date().timeIntervalSince(startTime)

        guard case .success(let files) = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssertEqual(files.count, 100)
        XCTAssert(elapsed < 2.0, "Scanning 100 files took \(elapsed) seconds, expected <2 seconds")
    }
}
