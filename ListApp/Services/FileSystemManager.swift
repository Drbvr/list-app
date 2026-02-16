import Foundation
import Core

/// Stub file system manager for iOS app.
/// Wraps Core's FileSystemManager protocol with iOS-specific concerns
/// (iCloud Drive access, security-scoped bookmarks, file coordination).
/// Currently returns mock data; will be replaced with real implementation in Phase 2.
@Observable
class AppFileSystemManager {

    var selectedFolders: [URL] = []
    var isScanning: Bool = false
    var lastScanDate: Date? = nil
    var error: String? = nil

    private let coreFileSystem = DefaultFileSystemManager()
    private let todoParser = ObsidianTodoParser()

    /// Stub: Select a folder from iCloud Drive.
    /// Real implementation will use UIDocumentPickerViewController.
    func selectFolder() {
        error = "Folder selection requires iCloud Drive setup"
    }

    /// Stub: Scan selected folders for markdown files and parse items.
    func scanFolders() async -> [Item] {
        isScanning = true
        defer {
            isScanning = false
            lastScanDate = Date()
        }

        // Simulate async delay
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Return mock data for now
        return MockData.allItems
    }

    /// Stub: Toggle a todo's completion status in its source file.
    func toggleTodoCompletion(_ item: Item) async -> Bool {
        // Real implementation will:
        // 1. Read the source file
        // 2. Find the checkbox line matching the item
        // 3. Toggle [ ] <-> [x]
        // 4. Write the file back
        return true
    }

    /// Stub: Write an item back to its source file.
    func writeItem(_ item: Item) async -> Bool {
        // Real implementation will use Core's FileSystemManager.writeFile
        return true
    }
}
