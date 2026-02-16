import SwiftUI
import Core

@Observable
class AppState {
    var items: [Item] = MockData.allItems
    var savedViews: [SavedView] = MockData.savedViews
    var listTypes: [ListType] = MockData.listTypes

    private let filterEngine = ItemFilterEngine()
    private let searchEngine = FullTextSearchEngine()
    private let tagHierarchyHelper = TagHierarchy()

    // MARK: - Computed Properties

    var allTags: [String] {
        Array(Set(items.flatMap { $0.tags })).sorted()
    }

    /// Top-level tag groups with their children and item counts
    var tagGroups: [(tag: String, count: Int, children: [(tag: String, count: Int)])] {
        var groups: [String: Set<String>] = [:]

        for item in items {
            for tag in item.tags {
                let parts = tag.split(separator: "/")
                let topLevel = String(parts[0])
                groups[topLevel, default: Set()].insert(tag)
            }
        }

        return groups.keys.sorted().map { topLevel in
            let children = groups[topLevel]!.sorted().map { childTag in
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
        guard !query.isEmpty else { return [] }
        let results = searchEngine.search(query: query, in: items)
        return results.map { $0.item }
    }
}
