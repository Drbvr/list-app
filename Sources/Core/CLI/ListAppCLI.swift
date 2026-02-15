import Foundation

/// Error type for CLI operations
public enum CLIError: Error {
    case invalidCommand
    case fileNotFound(String)
    case parseFailed(String)
    case encodingFailed(String)
}

/// Main CLI class for list-app
public class ListAppCLI {

    private let fileSystem: FileSystemManager
    private let todoParser = ObsidianTodoParser()
    private let filterEngine = ItemFilterEngine()
    private let searchEngine = FullTextSearchEngine()
    private let viewManager: DefaultViewManager
    private let yamlParser = YAMLFrontmatterParser()

    public init(fileSystem: FileSystemManager) {
        self.fileSystem = fileSystem
        self.viewManager = DefaultViewManager(fileSystem: fileSystem)
    }

    /// Parse command-line arguments into a command
    public func parseCommand(_ args: [String]) -> CLICommand {
        guard !args.isEmpty else {
            return .help
        }

        let command = args[0]

        switch command {
        case "help", "-h", "--help":
            return .help

        case "scan":
            guard args.count >= 2 else { return .help }
            return .scan(args[1])

        case "list":
            guard args.count >= 2 else { return .help }
            let path = args[1]
            let filters = parseFilters(Array(args.dropFirst(2)))
            return .list(path, filters)

        case "search":
            guard args.count >= 3 else { return .help }
            return .search(args[1], args[2])

        case "apply-view":
            guard args.count >= 3 else { return .help }
            return .applyView(args[1], args[2])

        case "parse":
            guard args.count >= 2 else { return .help }
            return .parse(args[1])

        case "list-views":
            guard args.count >= 2 else { return .help }
            return .listViews(args[1])

        default:
            return .help
        }
    }

    /// Execute a command and return JSON output or error
    public func execute(_ command: CLICommand) -> Result<String, CLIError> {
        switch command {
        case .help:
            return .success(getHelpText())

        case .scan(let path):
            return executeScan(path)

        case .list(let path, let filters):
            return executeList(path, filters: filters)

        case .search(let query, let path):
            return executeSearch(query, path: path)

        case .applyView(let name, let path):
            return executeApplyView(name, path: path)

        case .parse(let path):
            return executeParse(path)

        case .listViews(let path):
            return executeListViews(path)
        }
    }

    // MARK: - Private Command Implementations

    private func executeScan(_ path: String) -> Result<String, CLIError> {
        // Scan directory for markdown files
        let scanResult = fileSystem.scanDirectory(at: path, recursive: true)

        switch scanResult {
        case .success(let files):
            var items: [Item] = []
            var itemCounts: [String: Int] = [:]

            for filePath in files {
                let readResult = fileSystem.readFile(at: filePath)
                switch readResult {
                case .success(let content):
                    let parsedItems = todoParser.parseTodos(from: content, sourceFile: filePath)
                    items.append(contentsOf: parsedItems)

                    for item in parsedItems {
                        itemCounts[item.type, default: 0] += 1
                    }

                case .failure:
                    continue
                }
            }

            let result: [String: Any] = [
                "vault_path": path,
                "total_files": files.count,
                "total_items": items.count,
                "items_by_type": itemCounts
            ]

            return encodeJSON(result)

        case .failure(let error):
            return .failure(.parseFailed("Failed to scan directory: \(error)"))
        }
    }

    private func executeList(_ path: String, filters: ViewFilters) -> Result<String, CLIError> {
        // Scan and parse all files
        let items = scanAndParseVault(path)

        // Apply filters
        let filtered = filterEngine.apply(filters: filters, to: items)

        // Convert to JSON-serializable format
        let jsonItems = filtered.map { item -> [String: Any] in
            var dict: [String: Any] = [
                "id": item.id.uuidString,
                "type": item.type,
                "title": item.title,
                "tags": item.tags,
                "completed": item.completed,
                "source_file": item.sourceFile
            ]

            // Add due date if present
            if case .date(let date) = item.properties["dueDate"] {
                dict["due"] = ISO8601DateFormatter().string(from: date)
            }

            return dict
        }

        return encodeJSON(jsonItems)
    }

    private func executeSearch(_ query: String, path: String) -> Result<String, CLIError> {
        // Scan and parse all files
        let items = scanAndParseVault(path)

        // Search
        let results = searchEngine.search(query: query, in: items)

        // Convert to JSON-serializable format
        let jsonResults = results.map { result -> [String: Any] in
            let matches = result.matches.map { match -> [String: Any] in
                [
                    "field": match.field,
                    "range": [match.range.location, match.range.length]
                ]
            }

            let itemDict: [String: Any] = [
                "id": result.item.id.uuidString,
                "type": result.item.type,
                "title": result.item.title,
                "tags": result.item.tags,
                "completed": result.item.completed
            ]

            return [
                "item": itemDict,
                "score": result.score,
                "matches": matches
            ]
        }

        return encodeJSON(jsonResults)
    }

    private func executeApplyView(_ name: String, path: String) -> Result<String, CLIError> {
        // Load views
        let viewsPath = path.hasSuffix("/") ? path + "views" : path + "/views"
        let viewsResult = viewManager.loadViews(from: [viewsPath])

        switch viewsResult {
        case .success(let views):
            guard let view = views.first(where: { $0.name == name }) else {
                return .failure(.parseFailed("View '\(name)' not found"))
            }

            // Scan and parse all files
            let items = scanAndParseVault(path)

            // Apply view
            let filtered = viewManager.applyView(view, to: items)

            // Convert to JSON-serializable format
            let jsonItems = filtered.map { item -> [String: Any] in
                [
                    "id": item.id.uuidString,
                    "type": item.type,
                    "title": item.title,
                    "tags": item.tags,
                    "completed": item.completed,
                    "source_file": item.sourceFile
                ]
            }

            return encodeJSON(jsonItems)

        case .failure(let error):
            return .failure(.parseFailed("Failed to load views: \(error)"))
        }
    }

    private func executeParse(_ path: String) -> Result<String, CLIError> {
        let readResult = fileSystem.readFile(at: path)

        switch readResult {
        case .success(let content):
            let (frontmatter, body) = yamlParser.extractFrontmatter(from: content)

            let items = todoParser.parseTodos(from: body, sourceFile: path)

            let result: [String: Any] = [
                "file": path,
                "has_frontmatter": frontmatter != nil,
                "items_count": items.count,
                "items": items.map { item -> [String: Any] in
                    [
                        "id": item.id.uuidString,
                        "type": item.type,
                        "title": item.title,
                        "tags": item.tags,
                        "completed": item.completed
                    ]
                }
            ]

            return encodeJSON(result)

        case .failure(let error):
            return .failure(.fileNotFound("Failed to read file: \(error)"))
        }
    }

    private func executeListViews(_ path: String) -> Result<String, CLIError> {
        let viewsPath = path.hasSuffix("/") ? path + "views" : path + "/views"
        let viewsResult = viewManager.loadViews(from: [viewsPath])

        switch viewsResult {
        case .success(let views):
            let result = views.map { view -> [String: Any] in
                let filterCount = [
                    view.filters.tags != nil ? 1 : 0,
                    view.filters.itemTypes != nil ? 1 : 0,
                    view.filters.dueBefore != nil ? 1 : 0,
                    view.filters.dueAfter != nil ? 1 : 0,
                    view.filters.completed != nil ? 1 : 0,
                    view.filters.folders != nil ? 1 : 0
                ].reduce(0, +)

                return [
                    "name": view.name,
                    "display_style": view.displayStyle.rawValue,
                    "filter_count": filterCount
                ]
            }

            return encodeJSON(result)

        case .failure(let error):
            return .failure(.parseFailed("Failed to load views: \(error)"))
        }
    }

    // MARK: - Private Helpers

    private func parseFilters(_ args: [String]) -> ViewFilters {
        var filters = ViewFilters()
        var i = 0

        while i < args.count {
            let arg = args[i]

            switch arg {
            case "--type":
                if i + 1 < args.count {
                    filters.itemTypes = [args[i + 1]]
                    i += 2
                } else {
                    i += 1
                }

            case "--tags":
                if i + 1 < args.count {
                    filters.tags = args[i + 1].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    i += 2
                } else {
                    i += 1
                }

            case "--completed":
                filters.completed = true
                i += 1

            case "--incomplete":
                filters.completed = false
                i += 1

            case "--due-before":
                if i + 1 < args.count {
                    let formatter = ISO8601DateFormatter()
                    if let date = formatter.date(from: args[i + 1]) {
                        filters.dueBefore = date
                    }
                    i += 2
                } else {
                    i += 1
                }

            case "--due-after":
                if i + 1 < args.count {
                    let formatter = ISO8601DateFormatter()
                    if let date = formatter.date(from: args[i + 1]) {
                        filters.dueAfter = date
                    }
                    i += 2
                } else {
                    i += 1
                }

            case "--folders":
                if i + 1 < args.count {
                    filters.folders = args[i + 1].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    i += 2
                } else {
                    i += 1
                }

            default:
                i += 1
            }
        }

        return filters
    }

    private func scanAndParseVault(_ path: String) -> [Item] {
        let scanResult = fileSystem.scanDirectory(at: path, recursive: true)

        var items: [Item] = []

        switch scanResult {
        case .success(let files):
            for filePath in files {
                let readResult = fileSystem.readFile(at: filePath)
                switch readResult {
                case .success(let content):
                    let parsedItems = todoParser.parseTodos(from: content, sourceFile: filePath)
                    items.append(contentsOf: parsedItems)
                case .failure:
                    continue
                }
            }

        case .failure:
            break
        }

        return items
    }

    private func encodeJSON(_ object: Any) -> Result<String, CLIError> {
        do {
            let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted])
            if let jsonString = String(data: data, encoding: .utf8) {
                return .success(jsonString)
            } else {
                return .failure(.encodingFailed("Failed to encode JSON"))
            }
        } catch {
            return .failure(.encodingFailed("JSON encoding error: \(error)"))
        }
    }

    private func getHelpText() -> String {
        return """
        list-app - Personal list management CLI

        USAGE:
            list-app <COMMAND> [OPTIONS]

        COMMANDS:
            help                Show this help text
            scan <PATH>         Scan vault and show statistics
            list <PATH>         List all items from vault
            search <QUERY>      Search items by query
            apply-view <NAME>   Apply a saved view to vault
            parse <FILE>        Parse a single markdown file
            list-views <PATH>   List all available views

        OPTIONS:
            --type <TYPE>       Filter by item type (e.g., todo, book)
            --tags <TAG>        Filter by tags (comma-separated)
            --completed         Show only completed items
            --incomplete        Show only incomplete items
            --due-before <DATE> Filter items due before date
            --due-after <DATE>  Filter items due after date
            --folders <FOLDER>  Filter by folders (comma-separated)

        EXAMPLES:
            list-app scan /vault
            list-app list /vault --type todo --incomplete
            list-app search "urgent" /vault
            list-app apply-view "Work Tasks" /vault
            list-app parse /vault/tasks.md
            list-app list-views /vault

        OUTPUT:
            All commands output JSON by default.
        """
    }
}

// MARK: - CLI Command Enum

public enum CLICommand: Equatable {
    case help
    case scan(String)
    case list(String, ViewFilters)
    case search(String, String)
    case applyView(String, String)
    case parse(String)
    case listViews(String)

    public static func == (lhs: CLICommand, rhs: CLICommand) -> Bool {
        switch (lhs, rhs) {
        case (.help, .help):
            return true
        case (.scan(let a), .scan(let b)):
            return a == b
        case (.list(let a1, _), .list(let b1, _)):
            return a1 == b1
        case (.search(let a1, let a2), .search(let b1, let b2)):
            return a1 == b1 && a2 == b2
        case (.applyView(let a1, let a2), .applyView(let b1, let b2)):
            return a1 == b1 && a2 == b2
        case (.parse(let a), .parse(let b)):
            return a == b
        case (.listViews(let a), .listViews(let b)):
            return a == b
        default:
            return false
        }
    }
}
