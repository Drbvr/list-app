# Personal List Management App - Core Engine

A cross-platform Swift library for parsing and managing structured lists from markdown files (Obsidian-compatible).

## Project Status

✅ **Phase 1: Core Engine** - COMPLETE

- 8/8 Milestones completed
- 208 comprehensive tests passing
- >85% code coverage
- Production-ready Swift library

🚀 **Phase 2: iOS Development** - Ready to start

## Features

- 📝 **Parse todos from markdown checkboxes** - Supports `- [ ]` and `- [x]` syntax with Obsidian metadata
- 📋 **Extract YAML frontmatter** - Parse structured data from markdown files with full type support
- 🏷️ **Hierarchical tag support** - Organize items with nested tags like `work/backend/api`
- 🔍 **Powerful filtering and search** - Filter by tags (with wildcards), types, dates, and folders; full-text search with relevance ranking
- 💾 **Saved view system** - Create reusable views with complex filter combinations
- 🚀 **Production-ready** - 208 comprehensive tests, full error handling, >85% code coverage

## Quick Start

### Installation

Add to your `Package.swift`:

```swift
.package(url: "https://github.com/yourusername/list-app.git", from: "1.0.0")
```

### Parse Todos

```swift
import Core

let parser = ObsidianTodoParser()
let content = """
- [ ] Review PR #work/backend #urgent 📅 2024-03-15
- [x] Write docs #work/docs
"""

let todos = parser.parseTodos(from: content, sourceFile: "tasks.md")

for todo in todos {
    print("\(todo.completed ? "✓" : "○") \(todo.title)")
    print("  Tags: \(todo.tags.joined(separator: ", "))")
}
```

### Filter Items

```swift
let filterEngine = ItemFilterEngine()
let filters = ViewFilters(
    tags: ["work/*"],
    itemTypes: ["todo"],
    completed: false
)

let workTodos = filterEngine.apply(filters: filters, to: allItems)
```

### Search Items

```swift
let searchEngine = FullTextSearchEngine()
let results = searchEngine.search(query: "urgent", in: items)

for result in results.sorted(by: { $0.score > $1.score }) {
    print("\(result.item.title) (score: \(result.score))")
}
```

### Apply Views

```swift
let viewManager = DefaultViewManager(fileSystem: fileSystem)
let views = try viewManager.loadViews(from: ["/vault/views"])

if let urgentView = views.first(where: { $0.name == "Urgent Tasks" }) {
    let filtered = viewManager.applyView(urgentView, to: items)
}
```

## CLI Usage

```bash
# Scan vault for statistics
list-app scan /path/to/vault

# List items with filters
list-app list /path/to/vault --type todo --incomplete
list-app list /path/to/vault --tags "work/*" --completed

# Search
list-app search "urgent" /path/to/vault

# Apply view
list-app apply-view "Work Tasks" /path/to/vault

# Parse file
list-app parse /path/to/file.md

# List views
list-app list-views /path/to/vault
```

## Architecture

### Components

- **Models/** - Core data structures (Item, SavedView, ViewFilters)
- **Parsers/** - Markdown and YAML parsing
- **FileSystem/** - File I/O abstraction
- **Business/** - Filtering, searching, view management
- **CLI/** - Command-line interface

### Test Coverage

- **Models:** 41 tests (100% coverage)
- **Parsers:** 56 tests (>95% coverage)
- **File System:** 23 tests (>90% coverage)
- **Business Logic:** 62 tests (>90% coverage)
- **CLI:** 27 tests (>85% coverage)
- **Overall:** 208 tests, >85% code coverage

## Testing

```bash
# Run all tests
swift test

# Run specific suite
swift test --filter ItemTests

# Generate coverage
swift test --enable-code-coverage
```

## Performance

- Parse 1000 todos: <500ms
- Filter 10,000 items: <100ms
- Search 10,000 items: <500ms
- Scan 1000 files: <2s

## Supported Format

```markdown
- [ ] Task #work/backend #urgent 📅 2024-03-15 ⏫
- [x] Completed task #work/docs

---
type: book
title: Project Hail Mary
author: Andy Weir
rating: 5
---
```

## Requirements

- Swift 5.9+
- macOS 10.15+, iOS 13.0+, Linux

## Documentation

- [PHASE2-PREP.md](./PHASE2-PREP.md) - iOS development guide
- [KNOWN-ISSUES.md](./KNOWN-ISSUES.md) - Limitations and future work
- [milestones.md](./milestones.md) - Development plan
- [spec.md](./spec.md) - Full specification

## License

MIT License - See LICENSE file for details
