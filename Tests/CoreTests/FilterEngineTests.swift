import Foundation
import XCTest

#if canImport(Core)
import Core
#endif

final class FilterEngineTests: XCTestCase {

    var engine: ItemFilterEngine!
    var testItems: [Item]!

    override func setUp() {
        super.setUp()
        engine = ItemFilterEngine()

        // Create test items
        testItems = [
            Item(type: "todo", title: "Review PR", tags: ["work/backend", "urgent"], completed: false, sourceFile: "/Work/todo.md"),
            Item(type: "todo", title: "Fix bug", tags: ["work/backend"], completed: false, sourceFile: "/Work/todo.md"),
            Item(type: "todo", title: "Write docs", tags: ["work/docs"], completed: true, sourceFile: "/Work/todo.md"),
            Item(type: "book", title: "Project Hail Mary", tags: ["books/read", "sci-fi"], completed: false, sourceFile: "/Books/books.md"),
            Item(type: "book", title: "Clean Code", tags: ["books/read", "programming"], completed: true, sourceFile: "/Books/books.md"),
            Item(type: "movie", title: "Inception", tags: ["movies/watched", "sci-fi"], completed: true, sourceFile: "/Movies/movies.md"),
        ]
    }

    // MARK: - Tag Filtering Tests

    func testFilterByExactTag() {
        let filters = ViewFilters(tags: ["work/backend"])
        let result = engine.apply(filters: filters, to: testItems)

        XCTAssertEqual(result.count, 2)
        XCTAssert(result.allSatisfy { $0.tags.contains("work/backend") })
    }

    func testFilterByMultipleTags() {
        let filters = ViewFilters(tags: ["work/backend", "work/docs"])
        let result = engine.apply(filters: filters, to: testItems)

        XCTAssertEqual(result.count, 3)  // OR logic
    }

    func testFilterByWildcardTag() {
        let filters = ViewFilters(tags: ["work/*"])
        let result = engine.apply(filters: filters, to: testItems)

        XCTAssertEqual(result.count, 3)  // All work items
        XCTAssert(result.allSatisfy { $0.tags.contains { $0.hasPrefix("work/") } })
    }

    func testFilterByTagNoMatch() {
        let filters = ViewFilters(tags: ["nonexistent"])
        let result = engine.apply(filters: filters, to: testItems)

        XCTAssertEqual(result.count, 0)
    }

    func testFilterByTagCaseSensitive() {
        let filters = ViewFilters(tags: ["Work/Backend"])
        let result = engine.apply(filters: filters, to: testItems)

        XCTAssertEqual(result.count, 0)  // Case sensitive
    }

    // MARK: - Type Filtering Tests

    func testFilterByType() {
        let filters = ViewFilters(itemTypes: ["todo"])
        let result = engine.apply(filters: filters, to: testItems)

        XCTAssertEqual(result.count, 3)
        XCTAssert(result.allSatisfy { $0.type == "todo" })
    }

    func testFilterByMultipleTypes() {
        let filters = ViewFilters(itemTypes: ["todo", "book"])
        let result = engine.apply(filters: filters, to: testItems)

        XCTAssertEqual(result.count, 5)
    }

    // MARK: - Completion Status Tests

    func testFilterCompleted() {
        let filters = ViewFilters(completed: true)
        let result = engine.apply(filters: filters, to: testItems)

        XCTAssertEqual(result.count, 3)
        XCTAssert(result.allSatisfy { $0.completed })
    }

    func testFilterIncomplete() {
        let filters = ViewFilters(completed: false)
        let result = engine.apply(filters: filters, to: testItems)

        XCTAssertEqual(result.count, 3)
        XCTAssert(result.allSatisfy { !$0.completed })
    }

    // MARK: - Folder Filtering Tests

    func testFilterByFolder() {
        let filters = ViewFilters(folders: ["Work"])
        let result = engine.apply(filters: filters, to: testItems)

        XCTAssertEqual(result.count, 3)  // All work items
    }

    func testFilterByMultipleFolders() {
        let filters = ViewFilters(folders: ["Work", "Books"])
        let result = engine.apply(filters: filters, to: testItems)

        XCTAssertEqual(result.count, 5)
    }

    // MARK: - Date Filtering Tests

    func testFilterByDueBefore() {
        let tomorrow = Date().addingTimeInterval(86400)
        let items = [
            Item(type: "todo", title: "Task 1", properties: ["dueDate": .date(Date())], completed: false, sourceFile: "test.md"),
            Item(type: "todo", title: "Task 2", properties: ["dueDate": .date(tomorrow)], completed: false, sourceFile: "test.md"),
            Item(type: "todo", title: "Task 3", properties: [:], completed: false, sourceFile: "test.md"),
        ]

        let filters = ViewFilters(dueBefore: tomorrow)
        let result = engine.apply(filters: filters, to: items)

        XCTAssertEqual(result.count, 1)  // Only Task 1
    }

    func testFilterByDueAfter() {
        let yesterday = Date().addingTimeInterval(-86400)
        let tomorrow = Date().addingTimeInterval(86400)
        let items = [
            Item(type: "todo", title: "Task 1", properties: ["dueDate": .date(yesterday)], completed: false, sourceFile: "test.md"),
            Item(type: "todo", title: "Task 2", properties: ["dueDate": .date(tomorrow)], completed: false, sourceFile: "test.md"),
        ]

        let filters = ViewFilters(dueAfter: Date())
        let result = engine.apply(filters: filters, to: items)

        XCTAssertEqual(result.count, 1)  // Only Task 2
    }

    // MARK: - Combined Filters Tests

    func testCombinedFilters() {
        let filters = ViewFilters(
            tags: ["work/*"],
            itemTypes: ["todo"],
            completed: false
        )
        let result = engine.apply(filters: filters, to: testItems)

        XCTAssertEqual(result.count, 2)  // Review PR, Fix bug
        XCTAssert(result.allSatisfy { $0.type == "todo" && !$0.completed && $0.tags.contains { $0.hasPrefix("work/") } })
    }

    func testEmptyFilters() {
        let filters = ViewFilters()
        let result = engine.apply(filters: filters, to: testItems)

        XCTAssertEqual(result.count, testItems.count)  // All items
    }

    func testFilterNoMatches() {
        let filters = ViewFilters(tags: ["nonexistent"], itemTypes: ["invalid"])
        let result = engine.apply(filters: filters, to: testItems)

        XCTAssertEqual(result.count, 0)
    }

    // MARK: - Performance Tests

    func testPerformanceWithManyItems() {
        var manyItems: [Item] = []

        for i in 0..<10000 {
            let item = Item(
                type: i % 3 == 0 ? "todo" : (i % 3 == 1 ? "book" : "movie"),
                title: "Item \(i)",
                tags: ["tag\(i % 100)", "work/section\(i % 10)"],
                completed: i % 2 == 0,
                sourceFile: "/folder\(i % 5)/file.md"
            )
            manyItems.append(item)
        }

        let filters = ViewFilters(tags: ["work/*"], itemTypes: ["todo"], completed: false)

        let startTime = Date()
        let result = engine.apply(filters: filters, to: manyItems)
        let elapsed = Date().timeIntervalSince(startTime)

        XCTAssert(elapsed < 0.1, "Filtering 10,000 items took \(elapsed) seconds, expected <0.1s")
        XCTAssert(result.count > 0)
    }
}

final class TagHierarchyTests: XCTestCase {

    var hierarchy: TagHierarchy!

    override func setUp() {
        super.setUp()
        hierarchy = TagHierarchy()
    }

    func testExpandWildcardSingleLevel() {
        let tags = Set(["work/backend", "work/frontend", "personal/projects"])
        let expanded = hierarchy.expandWildcard(tag: "work/*", in: tags)

        XCTAssertEqual(expanded.count, 2)
        XCTAssert(expanded.contains("work/backend"))
        XCTAssert(expanded.contains("work/frontend"))
    }

    func testExpandWildcardMultiLevel() {
        let tags = Set(["work/backend/api", "work/backend/db", "work/frontend"])
        let expanded = hierarchy.expandWildcard(tag: "work/*", in: tags)

        // Should only match direct children
        XCTAssertEqual(expanded.count, 1)
        XCTAssert(expanded.contains("work/frontend"))
    }

    func testGetDescendants() {
        let tags = Set(["work/backend", "work/backend/api", "work/backend/api/rest", "work/frontend"])
        let descendants = hierarchy.getDescendants(of: "work/backend", in: tags)

        XCTAssertEqual(descendants.count, 2)
        XCTAssert(descendants.contains("work/backend/api"))
        XCTAssert(descendants.contains("work/backend/api/rest"))
    }

    func testGetAncestors() {
        let ancestors = hierarchy.getAncestors(of: "work/backend/api/rest")

        XCTAssertEqual(ancestors.count, 4)
        XCTAssert(ancestors.contains("work"))
        XCTAssert(ancestors.contains("work/backend"))
        XCTAssert(ancestors.contains("work/backend/api"))
        XCTAssert(ancestors.contains("work/backend/api/rest"))
    }

    func testMatchesExactTag() {
        XCTAssert(hierarchy.matches(tag: "work/backend", pattern: "work/backend"))
        XCTAssertFalse(hierarchy.matches(tag: "work/backend", pattern: "work/frontend"))
    }

    func testMatchesWildcard() {
        XCTAssert(hierarchy.matches(tag: "work/backend", pattern: "work/*"))
        XCTAssert(hierarchy.matches(tag: "work/frontend", pattern: "work/*"))
        XCTAssertFalse(hierarchy.matches(tag: "work/backend/api", pattern: "work/*"))
    }
}

final class SearchEngineTests: XCTestCase {

    var engine: FullTextSearchEngine!
    var testItems: [Item]!

    override func setUp() {
        super.setUp()
        engine = FullTextSearchEngine()

        testItems = [
            Item(type: "todo", title: "Fix authentication bug", tags: ["work/backend", "urgent"], completed: false, sourceFile: "test.md"),
            Item(type: "todo", title: "Review authentication PR", tags: ["work/backend"], completed: false, sourceFile: "test.md"),
            Item(type: "book", title: "Authentication Best Practices", tags: ["security"], completed: true, sourceFile: "test.md"),
            Item(type: "todo", title: "Update documentation", tags: ["work/docs"], completed: false, sourceFile: "test.md"),
        ]
    }

    func testSearchExactMatch() {
        let results = engine.search(query: "authentication", in: testItems)

        XCTAssertEqual(results.count, 3)
        XCTAssert(results.allSatisfy { $0.score > 0 })
    }

    func testSearchCaseInsensitive() {
        let results1 = engine.search(query: "authentication", in: testItems)
        let results2 = engine.search(query: "AUTHENTICATION", in: testItems)

        XCTAssertEqual(results1.count, results2.count)
    }

    func testSearchRanking() {
        let results = engine.search(query: "authentication", in: testItems)

        // Title matches should rank higher than tag matches
        if results.count >= 2 {
            let titleMatchScore = results.first { $0.item.title.lowercased().contains("authentication") }?.score ?? 0
            let noTitleScore = results.first { !$0.item.title.lowercased().contains("authentication") }?.score ?? 0

            XCTAssert(titleMatchScore > noTitleScore)
        }
    }

    func testSearchNoMatches() {
        let results = engine.search(query: "nonexistent", in: testItems)

        XCTAssertEqual(results.count, 0)
    }

    func testSearchEmptyQuery() {
        let results = engine.search(query: "", in: testItems)

        XCTAssertEqual(results.count, 0)
    }

    func testSearchWithSpecialCharacters() {
        let results = engine.search(query: ".", in: testItems)

        // Should handle special characters gracefully
        XCTAssertGreaterThanOrEqual(results.count, 0)
    }

    func testSearchMatches() {
        let results = engine.search(query: "authentication", in: testItems)

        XCTAssertGreaterThan(results.count, 0)

        for result in results {
            XCTAssertGreaterThan(result.matches.count, 0)
            for match in result.matches {
                XCTAssertFalse(match.field.isEmpty)
            }
        }
    }

    func testSearchResult() {
        let item = Item(type: "todo", title: "Test", properties: [:], completed: false, sourceFile: "test.md")
        let match = Match(field: "title", range: NSRange(location: 0, length: 4))
        let result = SearchResult(item: item, score: 5.0, matches: [match])

        XCTAssertEqual(result.item.title, "Test")
        XCTAssertEqual(result.score, 5.0)
        XCTAssertEqual(result.matches.count, 1)
        XCTAssertEqual(result.matches[0].field, "title")
    }
}
