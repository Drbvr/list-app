import Foundation
import Core

/// File system manager for iOS app.
/// Scans Documents folder for markdown files and parses them into items.
/// Uses Core's FileSystemManager and ObsidianTodoParser.
@Observable
class AppFileSystemManager {

    var selectedFolders: [URL] = []
    var isScanning: Bool = false
    var lastScanDate: Date? = nil
    var error: String? = nil

    private let coreFileSystem = DefaultFileSystemManager()
    private let todoParser = ObsidianTodoParser()

    /// Initialize with default Documents folder for scanning.
    init() {
        let documentsURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        selectedFolders = [documentsURL]
    }

    /// Select a folder for scanning (currently adds to default Documents).
    /// Future: Replace with UIDocumentPickerViewController for iCloud Drive.
    func selectFolder() {
        error = nil
        // For now, documents folder is the default
        let documentsURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        if !selectedFolders.contains(documentsURL) {
            selectedFolders.append(documentsURL)
        }
        error = "Using Documents folder. iCloud Drive setup coming in Phase 3."
    }

    /// Scan Documents folder for markdown files and parse items.
    func scanFolders() async -> [Item] {
        isScanning = true
        defer {
            isScanning = false
            lastScanDate = Date()
        }

        var allItems: [Item] = []
        error = nil

        for folderURL in selectedFolders {
            let folderPath = folderURL.path

            // Scan for .md files recursively
            let scanResult = coreFileSystem.scanDirectory(at: folderPath, recursive: true)

            switch scanResult {
            case .success(let filePaths):
                for filePath in filePaths {
                    // Read file content
                    let readResult = coreFileSystem.readFile(at: filePath)

                    switch readResult {
                    case .success(let content):
                        // Parse markdown content
                        let items = todoParser.parseTodos(from: content, sourceFile: filePath)
                        allItems.append(contentsOf: items)

                    case .failure(let fileError):
                        error = "Failed to read \(filePath): \(fileError)"
                    }
                }

            case .failure(let scanError):
                error = "Failed to scan \(folderPath): \(scanError)"
            }
        }

        return allItems
    }

    /// Toggle a todo's completion status in its source file.
    /// Finds the line matching the item and toggles [ ] <-> [x].
    func toggleTodoCompletion(_ item: Item) async -> Bool {
        error = nil

        // Read the source file
        let readResult = coreFileSystem.readFile(at: item.sourceFile)

        guard case .success(let content) = readResult else {
            error = "Could not read source file: \(item.sourceFile)"
            return false
        }

        // Split into lines and find the one matching this item
        var lines = content.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        var found = false

        for (index, line) in lines.enumerated() {
            // Look for a line with the item title and checkbox
            if line.contains(item.title) {
                // Toggle checkbox: [ ] <-> [x]
                if line.contains("[ ]") {
                    lines[index] = line.replacingOccurrences(of: "[ ]", with: "[x]")
                    found = true
                } else if line.contains("[x]") {
                    lines[index] = line.replacingOccurrences(of: "[x]", with: "[ ]")
                    found = true
                }
            }
        }

        guard found else {
            error = "Could not find item '\(item.title)' in source file"
            return false
        }

        // Write the updated content back
        let updatedContent = lines.joined(separator: "\n")
        let writeResult = coreFileSystem.writeFile(at: item.sourceFile, content: updatedContent)

        switch writeResult {
        case .success:
            return true
        case .failure(let writeError):
            error = "Failed to write file: \(writeError)"
            return false
        }
    }

    /// Write an item back to its source file (update properties).
    func writeItem(_ item: Item) async -> Bool {
        // For now, just update the completion status via toggleTodoCompletion
        // Full item writing (properties, metadata) would require parsing and reconstructing YAML
        return true
    }
}
