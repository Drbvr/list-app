# Personal List Management App - Implementation Plan
## Phase 1: Core Engine (Ubuntu VPS / Swift on Linux)

**Total Estimated Duration:** 8-12 weeks  
**Approach:** Ralph loop autonomous development  
**Test Strategy:** Test-Driven Development (TDD) - write failing tests first, then implement

---

## Prerequisites

### Development Environment Setup
- Swift 5.9+ installed on Ubuntu VPS
- Swift Package Manager configured
- Git repository initialized
- Testing framework: Swift Testing or XCTest

### Repository Structure
```
list-app/
├── Sources/
│   ├── Core/
│   │   ├── Models/
│   │   ├── Parsers/
│   │   ├── FileSystem/
│   │   └── Business/
│   └── CLI/
├── Tests/
│   ├── CoreTests/
│   └── IntegrationTests/
├── Package.swift
└── README.md
```

---

## 🎯 MILESTONE 1: Project Foundation & Data Models

**Goal:** Establish repository structure, define core data models, and set up testing infrastructure.

### Success Criteria
- [ ] Swift package initialized with proper structure
- [ ] All core data models defined with full property sets
- [ ] Models are Codable for serialization
- [ ] Basic unit tests pass for all models
- [ ] Test coverage >80% for model layer

### Core Models to Implement

**Item.swift:**
```swift
struct Item: Identifiable, Codable {
    let id: UUID
    var type: String  // "todo", "book", "movie", etc.
    var title: String
    var properties: [String: PropertyValue]  // Flexible property storage
    var tags: [String]  // Hierarchical tags like "work/linear/backend"
    var completed: Bool
    var sourceFile: String  // Path to source markdown file
    var createdAt: Date
    var updatedAt: Date
}

enum PropertyValue: Codable {
    case text(String)
    case number(Double)
    case date(Date)
    case bool(Bool)
}
```

**ListType.swift:**
```swift
struct ListType: Codable {
    let name: String
    var fields: [FieldDefinition]
    var llmExtractionPrompt: String?
}

struct FieldDefinition: Codable {
    let name: String
    let type: FieldType
    let required: Bool
    var min: Double?  // For number validation
    var max: Double?
}

enum FieldType: String, Codable {
    case text, number, date
}
```

**View.swift:**
```swift
struct SavedView: Codable {
    let name: String
    var filters: ViewFilters
    var displayStyle: DisplayStyle
}

struct ViewFilters: Codable {
    var tags: [String]?  // Support wildcards like "work/*"
    var itemTypes: [String]?
    var dueBefore: Date?
    var dueAfter: Date?
    var completed: Bool?
    var folders: [String]?
}

enum DisplayStyle: String, Codable {
    case list, card
}
```

### Testing Requirements
- Create test fixtures for each model
- Test JSON serialization/deserialization
- Test property validation (min/max for numbers)
- Test tag parsing (hierarchical structure)
- Test date handling (ISO format)

### Completion Signal
**Output:** `<promise>M1_PROJECT_FOUNDATION_COMPLETE</promise>`

### Smoke Test
```bash
swift test --filter ModelTests
# All model tests pass
# Coverage report shows >80% for Models directory
```

---

## 🎯 MILESTONE 2: Markdown Todo Parser

**Goal:** Parse markdown files to extract todo items with metadata (checkboxes, dates, tags, priority).

### Success Criteria
- [ ] Extract all `- [ ]` and `- [x]` checkboxes from markdown
- [ ] Parse Obsidian-style metadata (📅 dates, ⏫/🔼/🔽 priority, #tags)
- [ ] Handle todos without metadata gracefully
- [ ] Support multi-line todos
- [ ] Parse nested list structures
- [ ] Test coverage >90% for parser

### Parser Capabilities

**TodoParser.swift:**
```swift
protocol MarkdownParser {
    func parseTodos(from content: String, sourceFile: String) -> [Item]
}

class ObsidianTodoParser: MarkdownParser {
    func parseTodos(from content: String, sourceFile: String) -> [Item]
}
```

**Parsing Rules:**
- Checkbox: `- [ ]` (incomplete) or `- [x]` (complete)
- Date: `📅 YYYY-MM-DD` or `📅 YYYY-MM-DDTHH:MM`
- Priority: `⏫` (high/p1), `🔼` (medium/p2), `🔽` (low/p3)
- Tags: `#tag` or `#parent/child/grandchild`
- Multiple tags per todo supported

**Example Input:**
```markdown
# Work Tasks

- [ ] Review PR for authentication #work/backend #urgent 📅 2024-03-15 ⏫
- [x] Update documentation #work/docs 📅 2024-03-10
- [ ] Fix bug in auth flow #work/backend
  This is a multi-line description
  with additional context
```

**Expected Output:**
- 3 Item objects
- First item: incomplete, high priority, work/backend + urgent tags, due 2024-03-15
- Second item: completed, work/docs tag, due 2024-03-10
- Third item: incomplete, work/backend tag, no due date, has description

### Edge Cases to Handle
1. Todos without any metadata (just text)
2. Multiple date emojis (use first, ignore rest)
3. Invalid date formats (skip date parsing, log warning)
4. Mixed checkbox styles (`* [ ]` vs `- [ ]`)
5. Nested lists (todos under headers)
6. Code blocks (ignore checkboxes in code fences)
7. Quoted checkboxes (ignore checkboxes in blockquotes)
8. Empty checkboxes (`- [ ]` with no text)

### Testing Requirements
- **Unit tests:** Parse 20+ fixture files with various formats
- **Edge case tests:** All 8 edge cases covered
- **Regression tests:** Known problematic formats
- **Performance test:** Parse file with 1000+ todos in <1 second

### Test Fixtures Needed
```
Tests/Fixtures/
├── simple-todos.md           # Basic checkbox syntax
├── metadata-todos.md         # Full metadata (dates, tags, priority)
├── nested-todos.md           # Indented/hierarchical lists
├── edge-cases.md             # Malformed/unusual inputs
├── large-file.md             # Performance testing (1000+ items)
└── code-blocks.md            # Checkboxes in code (should ignore)
```

### Completion Signal
**Output:** `<promise>M2_TODO_PARSER_COMPLETE</promise>`

### Smoke Test
```bash
swift test --filter TodoParserTests
# All parser tests pass
# Run CLI command: ./list-app parse Tests/Fixtures/metadata-todos.md
# Should output JSON with all parsed todos, correct metadata extracted
```

---

## 🎯 MILESTONE 3: YAML Frontmatter Parser

**Goal:** Parse YAML frontmatter from markdown files for list types, views, and item metadata.

### Success Criteria
- [ ] Extract YAML frontmatter from markdown (between `---` delimiters)
- [ ] Parse list type definitions into `ListType` model
- [ ] Parse view definitions into `SavedView` model
- [ ] Parse item frontmatter into `Item` properties
- [ ] Handle malformed YAML gracefully (return errors, not crashes)
- [ ] Test coverage >90% for YAML parser

### Parser Capabilities

**YAMLParser.swift:**
```swift
protocol FrontmatterParser {
    func extractFrontmatter(from content: String) -> (yaml: String?, body: String)
    func parseListType(yaml: String) -> Result<ListType, ParseError>
    func parseView(yaml: String) -> Result<SavedView, ParseError>
    func parseItemProperties(yaml: String) -> Result<[String: PropertyValue], ParseError>
}

enum ParseError: Error {
    case invalidYAML(String)
    case missingRequiredField(String)
    case invalidFieldType(String, expected: String, got: String)
}
```

**Example Inputs:**

**List Type Definition:**
```markdown
---
type: list_type_definition
name: Book
---

fields:
  - name: title
    type: text
    required: true
  - name: rating
    type: number
    min: 1
    max: 5
    required: false
```

**View Definition:**
```yaml
---
type: view
name: Urgent Work Tasks
display_style: list
---

filters:
  tags: [work/*, urgent]
  item_types: [todo]
  due_before: +7d
  completed: false
```

**Item Frontmatter:**
```yaml
---
type: book
title: Project Hail Mary
author: Andy Weir
rating: 5
date_read: 2024-03-10
tags: [books/read, sci-fi]
---

# Project Hail Mary
Amazing book about...
```

### Edge Cases to Handle
1. Missing frontmatter delimiters (treat as body-only)
2. Malformed YAML (syntax errors, invalid indentation)
3. Missing required fields (return ParseError)
4. Type mismatches (string where number expected)
5. Empty frontmatter (`---\n---`)
6. Multiple `---` sections (use first only)
7. Frontmatter not at start of file (ignore)
8. YAML with unsupported features (anchors, aliases)

### Testing Requirements
- **Unit tests:** Parse 15+ valid YAML fixtures
- **Error tests:** All 8 edge cases return appropriate errors
- **Validation tests:** Type checking, required fields, min/max
- **Integration tests:** Full markdown → parsed objects

### Test Fixtures
```
Tests/Fixtures/
├── type-definitions/
│   ├── book-type.md
│   ├── movie-type.md
│   └── invalid-type.md
├── views/
│   ├── urgent-work.md
│   ├── reading-list.md
│   └── malformed-view.md
└── items/
    ├── book-item.md
    ├── todo-item.md
    └── missing-required.md
```

### Completion Signal
**Output:** `<promise>M3_YAML_PARSER_COMPLETE</promise>`

### Smoke Test
```bash
swift test --filter YAMLParserTests
# All tests pass
# CLI: ./list-app parse-type Tests/Fixtures/type-definitions/book-type.md
# Should output valid ListType JSON
# CLI: ./list-app parse-item Tests/Fixtures/items/book-item.md
# Should output Item with properties correctly typed
```

---

## 🎯 MILESTONE 4: File System Layer

**Goal:** Read/write markdown files, scan directories recursively, handle errors gracefully.

### Success Criteria
- [ ] Read markdown files from filesystem
- [ ] Write markdown files (create/update)
- [ ] Scan directories recursively with exclusions
- [ ] Watch for file changes (optional for Phase 1, nice-to-have)
- [ ] Handle file errors (permissions, disk full, missing files)
- [ ] Test coverage >85% for file operations

### File System Interface

**FileSystemManager.swift:**
```swift
protocol FileSystemManager {
    func readFile(at path: String) -> Result<String, FileError>
    func writeFile(at path: String, content: String) -> Result<Void, FileError>
    func scanDirectory(at path: String, recursive: Bool) -> Result<[String], FileError>
    func listSubdirectories(at path: String) -> Result<[String], FileError>
}

enum FileError: Error {
    case notFound(String)
    case permissionDenied(String)
    case diskFull
    case invalidPath(String)
    case ioError(String)
}
```

**FileScanner.swift:**
```swift
class FileScanner {
    let exclusions: [String] = [".obsidian", ".git", ".DS_Store"]
    
    func scanForMarkdown(in folders: [String]) -> Result<[MarkdownFile], FileError>
}

struct MarkdownFile {
    let path: String
    let content: String
    let modifiedAt: Date
    let folder: String  // Immediate parent folder
}
```

### Functionality Requirements

**Reading:**
- Read text files with UTF-8 encoding
- Handle large files (stream if >10MB)
- Return appropriate errors for missing/unreadable files

**Writing:**
- Create parent directories if needed
- Atomic writes (write to temp, then rename)
- Preserve file permissions
- Queue writes to batch operations

**Scanning:**
- Recursively scan subdirectories
- Auto-exclude: `.obsidian/`, `.git/`, `.DS_Store`, hidden files (`.filename`)
- Filter for `.md` extension only
- Return full paths and relative paths

### Edge Cases to Handle
1. Symlinks (follow or skip - decide)
2. File disappears during read (return error)
3. Concurrent writes to same file (last-write-wins)
4. Very deep directory hierarchies (>100 levels)
5. Filenames with special characters (spaces, unicode)
6. Large directories (1000+ files)
7. Permission errors mid-scan (continue, log errors)
8. Disk full during write (return error, don't corrupt)

### Testing Requirements
- **Mock filesystem:** Use temporary directories for tests
- **Unit tests:** Read/write/scan operations
- **Error simulation:** Trigger each FileError type
- **Integration tests:** End-to-end file operations
- **Performance tests:** Scan directory with 1000+ files in <2 seconds

### Test Structure
```swift
class FileSystemTests {
    var tempDir: URL!
    
    override func setUp() {
        // Create temp directory with test fixtures
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
    }
    
    override func tearDown() {
        // Clean up temp directory
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    func testReadMarkdownFile() { /* ... */ }
    func testWriteMarkdownFile() { /* ... */ }
    func testScanRecursive() { /* ... */ }
    func testExcludeHiddenFiles() { /* ... */ }
    func testHandlePermissionError() { /* ... */ }
}
```

### Completion Signal
**Output:** `<promise>M4_FILE_SYSTEM_COMPLETE</promise>`

### Smoke Test
```bash
swift test --filter FileSystemTests
# All tests pass
# CLI: ./list-app scan Tests/Fixtures/sample-vault/
# Should output list of markdown files, excluding .obsidian/
# CLI: ./list-app write /tmp/test.md "# Test"
# Should create file successfully
```

---

## 🎯 MILESTONE 5: Filter & Search Engine

**Goal:** Filter items by tags, dates, types, folders; hierarchical tag support; full-text search.

### Success Criteria
- [ ] Filter items by single or multiple tags
- [ ] Support tag wildcards (`work/*` matches `work/backend`, `work/frontend`)
- [ ] Filter by date ranges (relative and absolute)
- [ ] Filter by item types, completion status, folders
- [ ] Combine multiple filters (AND logic)
- [ ] Hierarchical tag drill-down (parent shows all children)
- [ ] Full-text search across title and content
- [ ] Test coverage >90% for filtering logic

### Filter Engine Interface

**FilterEngine.swift:**
```swift
protocol FilterEngine {
    func apply(filters: ViewFilters, to items: [Item]) -> [Item]
}

class ItemFilterEngine: FilterEngine {
    func apply(filters: ViewFilters, to items: [Item]) -> [Item] {
        var filtered = items
        
        if let tags = filters.tags {
            filtered = filterByTags(filtered, tags: tags)
        }
        
        if let types = filters.itemTypes {
            filtered = filtered.filter { types.contains($0.type) }
        }
        
        if let dueBefore = filters.dueBefore {
            filtered = filterByDueDate(filtered, before: dueBefore)
        }
        
        // ... additional filters
        
        return filtered
    }
}
```

**TagHierarchy.swift:**
```swift
struct TagHierarchy {
    func expandWildcard(tag: String, in allTags: Set<String>) -> Set<String>
    func getDescendants(of tag: String, in allTags: Set<String>) -> Set<String>
    func getAncestors(of tag: String) -> [String]
}

// Example:
// expandWildcard("work/*", in: ["work/backend", "work/frontend", "personal"])
// -> ["work/backend", "work/frontend"]
```

**SearchEngine.swift:**
```swift
protocol SearchEngine {
    func search(query: String, in items: [Item]) -> [SearchResult]
}

struct SearchResult {
    let item: Item
    let score: Double  // Relevance score
    let matches: [Match]  // Where query was found
}

struct Match {
    let field: String  // "title", "content", "tags"
    let range: Range<Int>
}
```

### Filter Capabilities

**Tag Filtering:**
- Exact match: `#work` matches only items tagged exactly "work"
- Wildcard: `#work/*` matches "work/backend", "work/frontend", etc.
- Multiple tags (OR): `[work/*, urgent]` matches items with either tag
- Hierarchical: Filtering by parent includes all children

**Date Filtering:**
- Relative: `+7d` (7 days from now), `-30d` (30 days ago)
- Absolute: `2024-03-15`, `2024-03-01T10:00:00Z`
- Ranges: `dueAfter` and `dueBefore` combine for range

**Type Filtering:**
- Single: `item_types: [todo]`
- Multiple: `item_types: [todo, book]`

**Completion Filtering:**
- Show completed only: `completed: true`
- Show incomplete only: `completed: false`
- Show all: `completed: null`

**Folder Filtering:**
- Exact: `folders: ["Work"]` matches items in `/Work/`
- Multiple: `folders: ["Work", "Projects"]`
- Full path matching: `/Work/Linear/Backend`

### Search Capabilities

**Text Search:**
- Search in: title, content, tags, custom properties
- Case-insensitive by default
- Word boundary matching
- Ranking by relevance (title matches > content matches)

**Ranking Algorithm:**
- Title exact match: 10 points
- Title contains: 5 points
- Tag match: 3 points
- Content match: 1 point per occurrence

### Edge Cases to Handle
1. Empty filter (return all items)
2. Filter matches nothing (return empty array)
3. Invalid date format in filter (skip date filter, log warning)
4. Wildcard with no matches (return empty)
5. Deeply nested tags (10+ levels)
6. Search query with special regex characters
7. Very long item lists (10,000+ items) - performance
8. Tags with unicode/emoji

### Testing Requirements
- **Unit tests:** Each filter type independently
- **Combination tests:** Multiple filters applied together
- **Wildcard tests:** All tag wildcard scenarios
- **Search tests:** Relevance ranking, edge cases
- **Performance tests:** Filter 10,000 items in <100ms

### Test Data
```swift
let testItems = [
    Item(type: "todo", title: "Review PR", tags: ["work/backend", "urgent"], ...),
    Item(type: "book", title: "Project Hail Mary", tags: ["books/to-read", "sci-fi"], ...),
    // ... 100+ test items covering all combinations
]
```

### Completion Signal
**Output:** `<promise>M5_FILTER_ENGINE_COMPLETE</promise>`

### Smoke Test
```bash
swift test --filter FilterEngineTests
# All tests pass
# CLI: ./list-app filter --tags "work/*" --type todo Tests/Fixtures/sample-vault/
# Should output only work-related todos
# CLI: ./list-app search "urgent" Tests/Fixtures/sample-vault/
# Should rank urgent items by relevance
```

---

## 🎯 MILESTONE 6: View System

**Goal:** Parse view definitions, apply filters, manage saved views.

### Success Criteria
- [ ] Parse view definition markdown files
- [ ] Load all views from configured folders
- [ ] Apply view filters to item collections
- [ ] Validate view definitions (required fields, valid filters)
- [ ] Handle relative date filters (`+7d`, `-30d`)
- [ ] Test coverage >85% for view system

### View System Interface

**ViewManager.swift:**
```swift
protocol ViewManager {
    func loadViews(from folders: [String]) -> Result<[SavedView], ViewError>
    func applyView(_ view: SavedView, to items: [Item]) -> [Item]
    func validateView(_ view: SavedView) -> Result<Void, ValidationError>
}

enum ViewError: Error {
    case invalidViewDefinition(String)
    case parseError(ParseError)
    case fileError(FileError)
}

enum ValidationError: Error {
    case missingRequiredField(String)
    case invalidFilterValue(String)
    case unsupportedFilterType(String)
}
```

**RelativeDateParser.swift:**
```swift
struct RelativeDateParser {
    func parse(_ input: String) -> Date?
    
    // Examples:
    // "+7d" -> 7 days from now
    // "-30d" -> 30 days ago
    // "+2w" -> 2 weeks from now
    // "-1m" -> 1 month ago
    // "+1y" -> 1 year from now
}
```

### View Definition Parsing

**View Format (from spec):**
```yaml
---
type: view
name: Urgent Work Tasks
display_style: list
---

filters:
  tags: [work/*, urgent]
  item_types: [todo]
  due_before: +7d
  completed: false
  folders: [Work, Projects]
```

**Parsing Steps:**
1. Extract YAML frontmatter (reuse M3 parser)
2. Validate `type: view` field exists
3. Parse `filters` object into `ViewFilters` struct
4. Convert relative dates to absolute dates
5. Validate filter values (e.g., valid item types)

### View Application Flow

```swift
let viewManager = ViewManager()

// 1. Load all views from folders
let views = try viewManager.loadViews(from: ["/vault/views"])

// 2. Get all items from vault
let items = /* ... scan and parse all items ... */

// 3. Apply a specific view
let urgentWorkView = views.first { $0.name == "Urgent Work Tasks" }!
let filteredItems = viewManager.applyView(urgentWorkView, to: items)

// Result: Only incomplete todos tagged "work/*" or "urgent", due within 7 days
```

### Validation Rules

**Required Fields:**
- `name` must be non-empty string
- `display_style` must be "list" or "card"

**Optional Fields:**
- All filter fields are optional
- Empty filters object means "show all"

**Filter Validation:**
- `tags`: Array of strings (can include wildcards)
- `item_types`: Array of valid type names
- `due_before`/`due_after`: Valid date or relative date string
- `completed`: Boolean or null
- `folders`: Array of valid folder paths

### Edge Cases to Handle
1. View with no filters (show all items)
2. View with invalid filter values (skip invalid, use valid ones)
3. Relative date in the past (`-7d` for `due_before` makes no sense - allow it)
4. Multiple views with same name (use first, log warning)
5. View file with parse errors (skip view, log error)
6. Empty view folder (return empty array)
7. Circular filter logic (not possible with current design)

### Testing Requirements
- **Unit tests:** Parse 10+ valid view definitions
- **Validation tests:** All validation rules enforced
- **Filter application tests:** Views correctly filter items
- **Relative date tests:** All relative date formats
- **Error handling tests:** Invalid views handled gracefully

### Test Fixtures
```
Tests/Fixtures/views/
├── urgent-work.md          # Valid view with all filters
├── simple-list.md          # Minimal view (name + display_style only)
├── reading-list.md         # View for book items
├── invalid-type.md         # Missing type: view field
├── invalid-filter.md       # Invalid filter values
└── relative-dates.md       # Uses +7d, -30d syntax
```

### Completion Signal
**Output:** `<promise>M6_VIEW_SYSTEM_COMPLETE</promise>`

### Smoke Test
```bash
swift test --filter ViewSystemTests
# All tests pass
# CLI: ./list-app list-views Tests/Fixtures/views/
# Should output all valid views with names
# CLI: ./list-app apply-view "Urgent Work Tasks" Tests/Fixtures/sample-vault/
# Should output filtered items matching view criteria
```

---

## 🎯 MILESTONE 7: CLI Prototype & Integration

**Goal:** Build command-line interface to demonstrate all features working together.

### Success Criteria
- [ ] CLI can scan vault folders
- [ ] CLI can list items with filtering
- [ ] CLI can apply saved views
- [ ] CLI can search items
- [ ] CLI can parse individual files
- [ ] CLI has help documentation
- [ ] Integration tests cover end-to-end workflows
- [ ] Test coverage >80% overall

### CLI Commands

**main.swift:**
```swift
enum Command {
    case scan(folders: [String])
    case list(filters: ViewFilters?)
    case applyView(name: String, vaultPath: String)
    case search(query: String, vaultPath: String)
    case parse(filePath: String)
    case listViews(vaultPath: String)
    case help
}
```

**Command Implementations:**

**1. Scan Command**
```bash
./list-app scan /path/to/vault

# Output:
# Scanning /path/to/vault...
# Found 145 markdown files
# Parsed 87 todos, 23 books, 12 movies
# Excluded: .obsidian/, .git/
```

**2. List Command**
```bash
./list-app list /path/to/vault --type todo --tags "work/*" --incomplete

# Output (JSON):
[
  {
    "id": "...",
    "type": "todo",
    "title": "Review PR for auth",
    "tags": ["work/backend", "urgent"],
    "completed": false,
    "due": "2024-03-15"
  },
  ...
]
```

**3. Apply View Command**
```bash
./list-app apply-view "Urgent Work Tasks" /path/to/vault

# Loads view from /path/to/vault/views/urgent-work-tasks.md
# Applies filters
# Outputs matching items (JSON)
```

**4. Search Command**
```bash
./list-app search "authentication bug" /path/to/vault

# Output (JSON with scores):
[
  {
    "item": { "id": "...", "title": "Fix auth bug", ... },
    "score": 8.5,
    "matches": [
      { "field": "title", "range": "5-19" }
    ]
  },
  ...
]
```

**5. Parse Command**
```bash
./list-app parse /path/to/file.md

# Output: Parsed structure (JSON)
# Shows: frontmatter, todos extracted, validation warnings
```

**6. List Views Command**
```bash
./list-app list-views /path/to/vault

# Output:
# Available views:
# - Urgent Work Tasks (list style, 3 filters)
# - Reading List (card style, 2 filters)
# - Completed This Week (list style, 4 filters)
```

### Integration Test Scenarios

**Test 1: Full Workflow**
1. Scan vault folder with mixed content
2. Parse todos, books, movies
3. Apply view filter
4. Verify correct items returned

**Test 2: Error Handling**
1. Scan non-existent folder → error message
2. Parse malformed markdown → warning, partial results
3. Apply non-existent view → error message

**Test 3: Large Vault Performance**
1. Create test vault with 1000+ items
2. Scan and parse → complete in <5 seconds
3. Apply complex filters → complete in <500ms
4. Search → complete in <1 second

### CLI Output Format

**JSON Mode (default):**
- Machine-readable
- All fields included
- Proper escaping

**Human Mode (`--human` flag):**
- Readable tables
- Truncated content
- Color coding (optional)

**Example Human Output:**
```
┌─────────┬──────────────────────┬────────────┬────────────────────┐
│ Type    │ Title                │ Tags       │ Due                │
├─────────┼──────────────────────┼────────────┼────────────────────┤
│ todo    │ Review PR for auth   │ work/back… │ 2024-03-15         │
│ todo    │ Fix bug in login     │ work/back… │ 2024-03-12 (⚠️ overdue) │
└─────────┴──────────────────────┴────────────┴────────────────────┘
```

### Testing Requirements
- **CLI tests:** Each command with valid/invalid inputs
- **Integration tests:** End-to-end workflows (scan → filter → output)
- **Performance tests:** Large vault handling
- **Error handling tests:** All error paths covered
- **Help text tests:** Help output is correct and complete

### Completion Signal
**Output:** `<promise>M7_CLI_PROTOTYPE_COMPLETE</promise>`

### Smoke Test
```bash
swift test --filter IntegrationTests
# All integration tests pass

# Manual smoke tests:
./list-app scan Tests/Fixtures/sample-vault/
./list-app list Tests/Fixtures/sample-vault/ --type todo
./list-app apply-view "Urgent Work" Tests/Fixtures/sample-vault/
./list-app search "urgent" Tests/Fixtures/sample-vault/

# All commands run without errors
# Output is correct JSON
# Performance is acceptable (<5s for scan, <500ms for filters)
```

---

## 🎯 MILESTONE 8: Documentation & Phase 2 Prep

**Goal:** Complete documentation, prepare for iOS development handoff.

### Success Criteria
- [ ] README with installation and usage instructions
- [ ] API documentation for all public interfaces
- [ ] Example code snippets for common operations
- [ ] Test coverage report generated
- [ ] Phase 2 transition guide written
- [ ] Known issues and limitations documented

### Documentation Deliverables

**1. README.md**
```markdown
# Personal List Management App - Core Engine

Cross-platform Swift library for parsing and managing structured lists
from markdown files (Obsidian-compatible).

## Features
- Parse todos from markdown checkboxes
- Extract YAML frontmatter
- Hierarchical tag support
- Powerful filtering and search
- Saved view system

## Installation
[Swift Package Manager instructions]

## Quick Start
[Code examples]

## CLI Usage
[Command reference]

## Architecture
[Component diagram]

## Testing
[How to run tests]
```

**2. API Documentation**
- Generate with Swift DocC or jazzy
- Cover all public protocols and classes
- Include code examples for each major component
- Document error types and handling

**3. Example Code**

**example-parse-todos.swift:**
```swift
import Core

let parser = ObsidianTodoParser()
let content = try String(contentsOfFile: "tasks.md")
let todos = parser.parseTodos(from: content, sourceFile: "tasks.md")

for todo in todos {
    print("\(todo.completed ? "✓" : "○") \(todo.title)")
    print("  Tags: \(todo.tags.joined(separator: ", "))")
}
```

**example-filter-items.swift:**
```swift
import Core

let engine = ItemFilterEngine()
let filters = ViewFilters(
    tags: ["work/*"],
    itemTypes: ["todo"],
    completed: false
)

let filtered = engine.apply(filters: filters, to: allItems)
print("Found \(filtered.count) matching items")
```

**4. Test Coverage Report**
```bash
swift test --enable-code-coverage
xcov --scheme list-app --minimum-coverage-percentage 80

# Generate HTML report showing:
# - Overall coverage: >80%
# - Per-module coverage
# - Untested code paths
```

**5. Phase 2 Transition Guide**

**PHASE2-PREP.md:**
```markdown
# Phase 2: iOS Implementation Guide

## What's Ready
- All core parsing and filtering logic
- Data models (Codable for easy serialization)
- File system abstraction (ready for iOS FileManager)
- Comprehensive test suite

## What's Next
1. Create Xcode project for iOS app
2. Import Core package as SPM dependency
3. Build SwiftUI views using Core models
4. Integrate Apple Intelligence for extraction
5. Add iCloud Drive file picker

## Architecture Notes
- Core package is platform-agnostic
- No UIKit/AppKit dependencies in Core
- ViewModels can directly use Core protocols

## Testing Strategy
- Keep unit tests in Core (Linux-compatible)
- Add UI tests in iOS project
- Use XCTest for both

## Key Integration Points
[Detailed technical notes]
```

**6. Known Issues & Limitations**

**KNOWN-ISSUES.md:**
```markdown
# Known Issues and Limitations

## Current Limitations
1. No file watching (iOS Phase 2 will add)
2. No support for recurring tasks (future)
3. Tag renaming requires manual find/replace (future)
4. Large files (>10MB) may be slow (needs optimization)

## Edge Cases Not Handled
1. Symlinks in vault folders (currently skipped)
2. Markdown files with non-UTF8 encoding (will fail)
3. Files with very long lines (>10,000 chars) may cause issues

## Performance Notes
- Tested with vaults up to 1,000 files
- Filtering scales linearly with item count
- Search performance degrades with >10,000 items

## Future Enhancements
[List of out-of-scope features from spec]
```

### Completion Signal
**Output:** `<promise>M8_PHASE1_COMPLETE</promise>`

**Final Output:**
```
<promise>PHASE1_COMPLETE</promise>

Phase 1 Core Engine: ✅ COMPLETE

Summary:
- 8/8 Milestones completed
- Test coverage: 87% overall
- 247 unit tests passing
- 18 integration tests passing
- CLI functional with 7 commands
- Documentation complete

Ready for Phase 2: iOS Development
```

### Smoke Test
```bash
# Verify all documentation exists
ls -la README.md API-DOCS/ EXAMPLES/ PHASE2-PREP.md KNOWN-ISSUES.md

# Generate and view test coverage
swift test --enable-code-coverage
open coverage-report.html

# Verify CLI works end-to-end
./list-app scan Tests/Fixtures/sample-vault/
./list-app apply-view "Urgent Work" Tests/Fixtures/sample-vault/

# Check that Core package builds on macOS (prep for iOS)
swift build --platform macos

# All checks pass ✅
```

---

## Ralph Loop Usage Guide

### Running Each Milestone

**Template:**
```bash
/ralph-loop "
Milestone [N]: [Title]

Goal: [Clear objective]

Success Criteria:
[Paste criteria from milestone]

Implementation Strategy:
1. Write failing tests first (TDD)
2. Implement minimal code to pass tests
3. Refactor for clarity
4. Add edge case tests
5. Verify smoke test passes

When complete, output: <promise>M[N]_[NAME]_COMPLETE</promise>

Context:
- Previous milestones: [list completed milestones]
- Dependencies: [any specific dependencies]
- Performance target: [if specified in milestone]

Edge Cases to Handle:
[Paste edge cases from milestone]

If blocked or unable to complete after 20 iterations:
- Document what's blocking progress
- List what was attempted
- Suggest alternative approaches
- Output: <promise>M[N]_BLOCKED</promise>
" --max-iterations 30
```

**Example for Milestone 1:**
```bash
/ralph-loop "
Milestone 1: Project Foundation & Data Models

Goal: Establish repository structure, define core data models, and set up testing infrastructure.

Success Criteria:
- Swift package initialized with proper structure
- All core data models defined with full property sets
- Models are Codable for serialization
- Basic unit tests pass for all models
- Test coverage >80% for model layer

Implementation Strategy:
1. Run 'swift package init --type library' to create package
2. Create Sources/Core/Models/ directory structure
3. Write Item.swift with all properties (TDD: write test first)
4. Write ListType.swift with validation
5. Write View.swift and ViewFilters
6. Run tests: swift test --enable-code-coverage
7. Verify coverage >80%

When complete, output: <promise>M1_PROJECT_FOUNDATION_COMPLETE</promise>

If blocked after 20 iterations:
- Document blocking issues
- Output: <promise>M1_BLOCKED</promise>
" --max-iterations 25
```

### Monitoring Progress

**Check status:**
```bash
# View git commits made by Ralph
git log --oneline --since="1 hour ago"

# Check test status
swift test

# View coverage
swift test --enable-code-coverage
```

**Between milestones:**
1. Review git history
2. Verify smoke test manually
3. Check test coverage report
4. Read any generated documentation
5. Start next milestone Ralph loop

### Handling Blocks

If Ralph outputs `<promise>M[N]_BLOCKED</promise>`:
1. Review the blocking issue documentation
2. Adjust prompt to provide more guidance
3. Consider breaking milestone into smaller pieces
4. Re-run with updated prompt

---

## Success Metrics

### Phase 1 Completion Criteria
- ✅ All 8 milestones completed
- ✅ Overall test coverage >80%
- ✅ CLI passes all smoke tests
- ✅ Documentation complete and accurate
- ✅ No critical bugs in known issues
- ✅ Performance targets met (scan <5s, filter <500ms)

### Quality Gates
- Every milestone must pass its smoke test
- No regressions in previous milestones
- Code coverage never drops below 80%
- All integration tests pass
- CLI is functional and user-friendly

---

## Timeline Estimate

**Optimistic:** 6-8 weeks (with Ralph running overnight)
**Realistic:** 10-12 weeks (accounting for blocks and reviews)
**Pessimistic:** 14-16 weeks (if major redesigns needed)

**Per Milestone:**
- M1-M3: 1-2 weeks each (parsing is complex)
- M4: 1 week (file I/O is straightforward)
- M5-M6: 2-3 weeks each (filtering logic is intricate)
- M7: 1-2 weeks (integration and polish)
- M8: 1 week (documentation)

---

## Next Steps

1. **Review this plan** - ensure it matches your vision
2. **Set up development environment** - Swift on Ubuntu VPS
3. **Initialize git repository** - commit this plan
4. **Start Milestone 1** - run first Ralph loop
5. **Iterate** - complete milestones sequentially

**Ready to start M1? Run the Ralph loop command above!**
