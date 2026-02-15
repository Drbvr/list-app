import Foundation
import XCTest

#if canImport(Core)
import Core
#endif

final class CLITests: XCTestCase {

    var cli: ListAppCLI!
    var fileSystem: TestFileSystemManager!
    var tempDir: URL!

    // Extension to check if result is failure
    func isFailure<T, E>(_ result: Result<T, E>) -> Bool {
        switch result {
        case .failure:
            return true
        case .success:
            return false
        }
    }

    override func setUp() {
        super.setUp()

        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        fileSystem = TestFileSystemManager()
        cli = ListAppCLI(fileSystem: fileSystem)
    }

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Command Parsing Tests

    func testParseHelpCommand() {
        let result = cli.parseCommand(["help"])
        XCTAssertEqual(result, .help)
    }

    func testParseHelpShortForm() {
        let result = cli.parseCommand(["-h"])
        XCTAssertEqual(result, .help)
    }

    func testParseHelpLongForm() {
        let result = cli.parseCommand(["--help"])
        XCTAssertEqual(result, .help)
    }

    func testParseScanCommand() {
        let result = cli.parseCommand(["scan", "/path/to/vault"])

        if case .scan(let path) = result {
            XCTAssertEqual(path, "/path/to/vault")
        } else {
            XCTFail("Expected scan command")
        }
    }

    func testParseListCommand() {
        let result = cli.parseCommand(["list", "/path/to/vault"])

        if case .list(let path, _) = result {
            XCTAssertEqual(path, "/path/to/vault")
        } else {
            XCTFail("Expected list command")
        }
    }

    func testParseListCommandWithFilters() {
        let result = cli.parseCommand(["list", "/path", "--type", "todo", "--completed"])

        if case .list(_, let filters) = result {
            XCTAssertEqual(filters.itemTypes, ["todo"])
            XCTAssertEqual(filters.completed, true)
        } else {
            XCTFail("Expected list command with filters")
        }
    }

    func testParseSearchCommand() {
        let result = cli.parseCommand(["search", "urgent", "/path/to/vault"])

        if case .search(let query, let path) = result {
            XCTAssertEqual(query, "urgent")
            XCTAssertEqual(path, "/path/to/vault")
        } else {
            XCTFail("Expected search command")
        }
    }

    func testParseApplyViewCommand() {
        let result = cli.parseCommand(["apply-view", "Work Tasks", "/path/to/vault"])

        if case .applyView(let name, let path) = result {
            XCTAssertEqual(name, "Work Tasks")
            XCTAssertEqual(path, "/path/to/vault")
        } else {
            XCTFail("Expected apply-view command")
        }
    }

    func testParseParseCommand() {
        let result = cli.parseCommand(["parse", "/path/to/file.md"])

        if case .parse(let path) = result {
            XCTAssertEqual(path, "/path/to/file.md")
        } else {
            XCTFail("Expected parse command")
        }
    }

    func testParseListViewsCommand() {
        let result = cli.parseCommand(["list-views", "/path/to/vault"])

        if case .listViews(let path) = result {
            XCTAssertEqual(path, "/path/to/vault")
        } else {
            XCTFail("Expected list-views command")
        }
    }

    func testParseInvalidCommand() {
        let result = cli.parseCommand(["invalid"])
        XCTAssertEqual(result, .help)
    }

    func testParseNoArguments() {
        let result = cli.parseCommand([])
        XCTAssertEqual(result, .help)
    }

    // MARK: - Scan Command Tests

    func testExecuteScanCommand() {
        // Setup test files
        fileSystem.files["/vault/task1.md"] = "- [ ] Task 1 #work"
        fileSystem.files["/vault/task2.md"] = "- [x] Task 2 #personal"
        fileSystem.files["/vault/.obsidian/config.json"] = "{}"

        let result = cli.execute(.scan("/vault"))

        switch result {
        case .success(let output):
            let data = output.data(using: .utf8)!
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            XCTAssertNotNil(json)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testExecuteScanNonexistentFolder() {
        let result = cli.execute(.scan("/nonexistent"))

        switch result {
        case .success(let output):
            // Empty folder is ok - nonexistent folder returns empty array
            let data = output.data(using: .utf8)!
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            XCTAssertNotNil(json)
        case .failure:
            break  // Also acceptable
        }
    }

    // MARK: - List Command Tests

    func testExecuteListCommand() {
        fileSystem.files["/vault/task1.md"] = "- [ ] Task 1 #work"
        fileSystem.files["/vault/task2.md"] = "- [x] Task 2 #personal"

        let result = cli.execute(.list("/vault", ViewFilters()))

        switch result {
        case .success(let output):
            let data = output.data(using: .utf8)!
            let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            XCTAssertNotNil(json)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testExecuteListWithFilters() {
        fileSystem.files["/vault/todo.md"] = "- [ ] Task #work"
        fileSystem.files["/vault/book.md"] = """
        ---
        type: book
        title: Reading
        ---
        """

        let filters = ViewFilters(itemTypes: ["todo"])
        let result = cli.execute(.list("/vault", filters))

        switch result {
        case .success(let output):
            let data = output.data(using: .utf8)!
            let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            XCTAssertNotNil(json)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - Search Command Tests

    func testExecuteSearchCommand() {
        fileSystem.files["/vault/urgent.md"] = "- [ ] Urgent task #urgent"
        fileSystem.files["/vault/normal.md"] = "- [ ] Normal task"

        let result = cli.execute(.search("urgent", "/vault"))

        switch result {
        case .success(let output):
            let data = output.data(using: .utf8)!
            let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            XCTAssertNotNil(json)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testExecuteSearchNoMatches() {
        fileSystem.files["/vault/task.md"] = "- [ ] Task"

        let result = cli.execute(.search("nonexistent", "/vault"))

        switch result {
        case .success(let output):
            let data = output.data(using: .utf8)!
            let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            XCTAssertEqual(json?.count, 0)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - Parse Command Tests

    func testExecuteParseCommand() {
        fileSystem.files["/file.md"] = """
        ---
        type: todo
        title: Test Task
        ---
        - [ ] Test task #test 📅 2024-03-15
        """

        let result = cli.execute(.parse("/file.md"))

        switch result {
        case .success(let output):
            let data = output.data(using: .utf8)!
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            XCTAssertNotNil(json)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testExecuteParseNonexistentFile() {
        let result = cli.execute(.parse("/nonexistent.md"))

        switch result {
        case .success:
            XCTFail("Expected failure for nonexistent file")
        case .failure:
            break  // Expected
        }
    }

    // MARK: - Apply View Command Tests

    func testExecuteApplyViewCommand() {
        fileSystem.files["/vault/task1.md"] = "- [ ] Work task #work"
        fileSystem.files["/vault/task2.md"] = "- [ ] Personal task #personal"
        fileSystem.files["/vault/views/work.md"] = """
        ---
        type: view
        name: Work Tasks
        item_types: [todo]
        tags: [work]
        ---
        """

        let result = cli.execute(.applyView("Work Tasks", "/vault"))

        switch result {
        case .success(let output):
            let data = output.data(using: .utf8)!
            let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            XCTAssertNotNil(json)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testExecuteApplyViewNotFound() {
        fileSystem.files["/vault/task.md"] = "- [ ] Task"

        let result = cli.execute(.applyView("Nonexistent", "/vault"))

        switch result {
        case .success:
            XCTFail("Expected failure for nonexistent view")
        case .failure:
            break  // Expected
        }
    }

    // MARK: - List Views Command Tests

    func testExecuteListViewsCommand() {
        fileSystem.files["/vault/views/work.md"] = """
        ---
        type: view
        name: Work Tasks
        display_style: list
        ---
        """
        fileSystem.files["/vault/views/reading.md"] = """
        ---
        type: view
        name: Reading List
        display_style: card
        ---
        """

        let result = cli.execute(.listViews("/vault"))

        switch result {
        case .success(let output):
            XCTAssert(output.contains("Work Tasks"))
            XCTAssert(output.contains("Reading List"))
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    func testExecuteListViewsEmpty() {
        let result = cli.execute(.listViews("/vault"))

        switch result {
        case .success(let output):
            // Should be valid JSON
            let data = output.data(using: .utf8)!
            let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            XCTAssertNotNil(json)
            XCTAssertEqual(json?.count, 0)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - Help Command Tests

    func testExecuteHelpCommand() {
        let result = cli.execute(.help)

        switch result {
        case .success(let output):
            XCTAssert(output.contains("scan") || output.contains("list") || output.contains("help"))
        case .failure(let error):
            XCTFail("Expected success, got error: \(error)")
        }
    }

    // MARK: - Integration Tests

    func testFullWorkflow() {
        // Setup test vault
        fileSystem.files["/vault/work.md"] = """
        - [ ] Review PR #work/backend #urgent 📅 2024-03-15
        - [x] Write docs #work/docs
        """
        fileSystem.files["/vault/personal.md"] = """
        - [ ] Read book #personal
        """
        fileSystem.files["/vault/views/urgent.md"] = """
        ---
        type: view
        name: Urgent Tasks
        item_types: [todo]
        tags: [urgent]
        completed: false
        ---
        """

        // 1. Scan vault
        let scanResult = cli.execute(.scan("/vault"))
        switch scanResult {
        case .success:
            break
        case .failure:
            XCTFail("Scan failed")
            return
        }

        // 2. List items
        let listResult = cli.execute(.list("/vault", ViewFilters()))
        switch listResult {
        case .success:
            break
        case .failure:
            XCTFail("List failed")
            return
        }

        // 3. Apply view
        let viewResult = cli.execute(.applyView("Urgent Tasks", "/vault"))
        switch viewResult {
        case .success:
            break
        case .failure:
            XCTFail("Apply view failed")
            return
        }

        // 4. Search
        let searchResult = cli.execute(.search("urgent", "/vault"))
        switch searchResult {
        case .success:
            break
        case .failure:
            XCTFail("Search failed")
            return
        }
    }

    func testErrorHandling() {
        // Parse nonexistent file should fail
        let parseResult = cli.execute(.parse("/nonexistent.md"))
        XCTAssertTrue(isFailure(parseResult))

        // Apply nonexistent view should fail
        fileSystem.files["/vault/task.md"] = "- [ ] Task"  // Add content so vault "exists"
        let viewResult = cli.execute(.applyView("Nonexistent", "/vault"))
        XCTAssertTrue(isFailure(viewResult))
    }
}


