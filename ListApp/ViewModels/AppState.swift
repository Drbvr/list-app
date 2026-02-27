import SwiftUI
import Core

@Observable
class AppState {
    var items: [Item]
    var savedViews: [SavedView] = MockData.savedViews
    var listTypes: [ListType] = MockData.listTypes

    private let filterEngine = ItemFilterEngine()
    private let searchEngine = FullTextSearchEngine()
    private let tagHierarchyHelper = TagHierarchy()
    private let fileSystemManager = AppFileSystemManager()

    init() {
        // Try to load from real files, fallback to mock data if no files found
        let documentsURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        let vaultURL = documentsURL.appendingPathComponent("ListAppVault")

        // Check if vault exists
        if FileManager.default.fileExists(atPath: vaultURL.path) {
            // Try to load real files (synchronously for init)
            var loadedItems: [Item] = []
            let coreFileSystem = DefaultFileSystemManager()
            let todoParser = ObsidianTodoParser()

            if case .success(let filePaths) = coreFileSystem.scanDirectory(at: vaultURL.path, recursive: true) {
                for filePath in filePaths {
                    if case .success(let content) = coreFileSystem.readFile(at: filePath) {
                        let items = todoParser.parseTodos(from: content, sourceFile: filePath)
                        loadedItems.append(contentsOf: items)
                    }
                }
            }

            // Use loaded items if found, otherwise fall back to mock
            self.items = loadedItems.isEmpty ? MockData.allItems : loadedItems
        } else {
            // No vault folder, use mock data
            self.items = MockData.allItems
        }
    }

    // MARK: - Computed Properties

    var allTags: [String] {
        Array(Set(items.flatMap { $0.tags })).sorted()
    }

    /// Top-level tag groups with their children and item counts
    var tagGroups: [(tag: String, count: Int, children: [(tag: String, count: Int)])] {
        var groups: [String: Set<String>] = [:]

        for item in items {
            for tag in item.tags {
                guard !tag.isEmpty else { continue }
                let parts = tag.split(separator: "/")
                guard let firstPart = parts.first else { continue }
                let topLevel = String(firstPart)
                groups[topLevel, default: Set()].insert(tag)
            }
        }

        return groups.keys.sorted().map { topLevel in
            let childrenSet = groups[topLevel] ?? Set()
            let children = childrenSet.sorted().map { childTag in
                let count = items.filter { $0.tags.contains(childTag) }.count
                return (tag: childTag, count: count)
            }
            let totalCount = items.filter { item in
                item.tags.contains { $0.hasPrefix(topLevel) }
            }.count
            return (tag: topLevel, count: totalCount, children: children)
        }
    }

    var itemTypeNames: [String] {
        Array(Set(items.map { $0.type })).sorted()
    }

    // MARK: - Actions

    func toggleCompletion(for item: Item) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].completed.toggle()
            items[index].updatedAt = Date()

            // Persist change to file asynchronously
            Task {
                _ = await fileSystemManager.toggleTodoCompletion(items[index])
            }
        }
    }

    func deleteItem(_ item: Item) {
        items.removeAll { $0.id == item.id }
    }

    // MARK: - Filtering

    func filteredItems(for view: SavedView) -> [Item] {
        filterEngine.apply(filters: view.filters, to: items)
    }

    func filteredItems(with filters: ViewFilters) -> [Item] {
        filterEngine.apply(filters: filters, to: items)
    }

    // MARK: - Search

    func searchItems(query: String) -> [Item] {
        guard !query.isEmpty else { return items }  // Return all items when search is empty
        let results = searchEngine.search(query: query, in: items)
        return results.map { $0.item }
    }
}
