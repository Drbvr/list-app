# Personal List Management App - Product Specification

**Version:** 1.0  
**Date:** February 15, 2026  
**Status:** Phase 1 - Core Engine Development

---

## Executive Summary

A native iOS/macOS app for managing structured lists (todos, books, movies, restaurants, etc.) using Obsidian markdown folders as the storage backend. The app provides a unified interface for creating, viewing, filtering, and managing items across multiple list types, with on-device Apple Intelligence for content processing and type detection.

---

## Core Requirements

### 1. Storage Backend
- **Primary storage**: Markdown files in user-selected folder(s) from iCloud Drive
- **Not restricted to Obsidian vaults**: Any folder structure is supported
- **Multi-folder support**: User can select multiple subfolders, subfolders are automatically included
- **Direct file access**: Read/write local filesystem, let iCloud handle sync automatically
- **No duplication**: Centralized views are live queries over markdown files, not separate storage

### 2. List Type System

#### Two Storage Patterns
1. **Todo items**: Checkbox lists within markdown notes (`- [ ]` syntax)
2. **Other item types**: Individual notes with YAML frontmatter + markdown body

#### List Type Definitions
- Stored as YAML in individual notes (one note per type definition)
- User can create custom types beyond built-in ones
- Built-in types ship with app: Todo, Book, Movie, Restaurant, Place to Visit

**Type Definition Format:**
```yaml
---
type: list_type_definition
name: Book
---

fields:
  - name: title
    type: text
    required: true
  - name: author
    type: text
    required: false
  - name: isbn
    type: text
    required: false
  - name: rating
    type: number
    min: 1
    max: 5
    required: false
  - name: date_read
    type: date
    required: false
  - name: date_added
    type: date
    required: false

llm_extraction_prompt: |
  [Optional custom prompt override for this type]
```

#### Item Storage Format

**Todos** (checkbox syntax in notes):
```markdown
# Work Tasks

- [ ] Review PR #work/linear #urgent 📅 2024-03-15 ⏫
- [x] Update documentation #work/docs 📅 2024-03-10
- [ ] Fix bug in auth flow #work/backend
```

**Other Items** (YAML frontmatter + content):
```markdown
---
type: book
title: Project Hail Mary
author: Andy Weir
isbn: 978-0593135204
rating: null
date_added: 2024-03-15
tags: [books/to-read, sci-fi]
---

# Project Hail Mary

Recommended by John. Looks interesting based on the premise about...

![Book Cover](attachments/project-hail-mary.jpg)
```

### 3. Metadata System

#### Tags
- Hierarchical nested tags using Obsidian syntax: `#work/linear/backend`
- No distinction between "projects" and "labels" - all are tags
- Tags provide filtering/grouping across all items
- Tag hierarchy supports parent→child drill-down views

#### Folder Structure
- Folder path becomes a filterable property (e.g., `/Todos/Work/Linear` → project: `Work/Linear`)
- Folders not used as primary organization (tags preferred)
- Useful for high-level separation when multiple folders selected

#### Todo Metadata (Obsidian Format)
- **Due date**: `📅 YYYY-MM-DD`
- **Priority**: `⏫` (high), `🔼` (medium), `🔽` (low)
- **Tags**: `#tag` or `#parent/child`
- **Completion**: `- [x]` for done, `- [ ]` for incomplete

#### Custom Fields (Other Types)
- Defined per list type in type definition
- Stored in YAML frontmatter
- Support types: text, number, date
- Optional min/max validation for numbers

### 4. Validation & Error Handling

#### Reading Data (Lenient)
- Parse gracefully, don't fail on malformed data
- Show items with parse warnings (inline ⚠️ badge)
- Include "Validation Errors" view listing problematic items
- Allow manual correction via app

#### Writing Data (Strict)
- Enforce type validation using native iOS controls
- Prevent creating invalid YAML/markdown
- Use date pickers, number steppers, text fields with validation

#### File Operation Errors
- Show persistent non-intrusive banner for write failures
- Banner stays until issue resolved
- Automatic retry on transient errors
- No retry dialogs (too disruptive)

#### File Exclusions
- Auto-exclude `.obsidian/` config folder
- Auto-exclude hidden files (`.filename`)
- Auto-exclude common template/config patterns
- No user configuration needed (no-regret exclusions)

### 5. On-Device Intelligence

#### Apple Intelligence Integration
- Use Apple's on-device models (no external API calls)
- Frameworks: Natural Language, Vision, Core ML
- Works offline after initial model download

#### Content Processing Flow
1. **Raw input** received (text, photo, share sheet, paste)
2. **Type detection**: Propose list type, show button grid for confirmation/override
3. **Property extraction**: Extract fields from raw content using on-device model
4. **Preview & confirm**: Show read-only preview with "Edit" or "Save" buttons

#### LLM Prompt Copy Feature
- Include "Copy LLM Prompt" button after type detection
- Generate prompt with raw input + YAML extraction instructions
- Editable default template in settings
- Per-type template override support (optional field in type definition)
- Only default template ships with app initially

**Example Generated Prompt:**
```
Extract structured data from the following input and return ONLY valid YAML:

Input:
[raw text/OCR result here]

Return format:
---
type: book
title: [extracted]
author: [extracted]
isbn: [extracted or null]
rating: [1-5 or null]
tags: [array of relevant tags]
---
```

### 6. User Interface Design

#### iOS Navigation Structure (SwiftUI)

**Primary Screens:**
1. **Saved Views** - List of user-created views
2. **Custom Filter** - Ad-hoc filtering interface with tag/type/date/folder pickers
3. **Tag Browser** - Hierarchical tag list (with item counts), drill down to filtered lists
4. **Search** - Free-text search across all content
5. **History** - Recently opened items
6. **Settings** - Folder selection, type management, preferences
7. **Validation Errors** - Items with parse warnings

#### Item List View
- **Display mode**: Item-level (not note-level)
- **Flattened**: Show all matching items across all notes
- **Inline editing**: Tap to edit fields directly
- **View configuration**: Each saved view specifies display style (list vs card)

**List Row Display:**
- Checkbox (todos only, inline toggle)
- Title/primary field
- Priority/importance indicator (emoji or color)
- Tags (truncated if many)
- Due date (if present)
- Warning badge (if validation errors)

#### Item Detail View
- **Editable frontmatter fields** at top (forms for each property)
- **Content area** below (markdown editor for note body)
- **Embedded images** displayed inline
- **Inline editing** (no separate edit mode)

#### Quick Capture Flow
1. Tap floating + button → raw input screen
2. Enter/paste text, take photo, or receive from share sheet
3. App proposes type → user confirms or changes via button grid
4. App extracts properties → shows preview
5. User taps "Edit" (refine) or "Save" (accept)
6. Item saved to default folder (configured in settings)

#### Interactions & Gestures

**Swipe Actions:**
- **Right swipe**: Toggle complete (todos) / Mark done (other types)
- **Left swipe**: Delete / Archive

**Long Press Menu:**
- Edit
- Duplicate
- Share (iOS share sheet)
- Copy LLM prompt
- Move to folder
- Open in Obsidian (if installed)

**Pull to Refresh:**
- Re-scan selected folders

**Keyboard Shortcuts (iPad):**
- Cmd+N: New item
- Cmd+F: Search
- Cmd+Z: Undo

#### Undo System
- **Per-session undo**: History cleared on app close
- **Cross-view undo**: Works across different screens/views
- **Stack-based**: Multiple levels of undo available during session

### 7. Saved Views System

#### View Storage
- Stored as markdown notes with YAML frontmatter
- One note per view in configured folder(s)

**View Definition Format:**
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

#### Filter Capabilities
- **Tags**: Include/exclude, support wildcards (`work/*`)
- **Item types**: Filter by list type
- **Date ranges**: Relative (`+7d`, `-30d`) or absolute
- **Completion status**: Show completed, incomplete, or both
- **Folders**: Scope to specific folders (overrides global folder selection)
- **Priority**: Filter by urgency level
- **Custom fields**: Filter on any frontmatter property

#### Display Styles
- **List**: Compact rows with checkbox/title/metadata
- **Card**: Larger cards with preview content

### 8. Todo Management Specifics

#### Storage Strategy
- **Single list per year**: All todos for current year in one note (e.g., `Todos 2025.md`)
- **Manual archive**: User triggers "Archive completed todos"
  - Moves completed items to archive note
  - Starts fresh list for new period
  - Incomplete todos stay in current list (manual migration if needed)

#### Todo Parsing
- Parse all `- [ ]` and `- [x]` in markdown notes
- Extract inline metadata (dates, tags, priority emoji)
- Support todos without metadata (show in views with "no due date", etc.)

#### Checkbox Toggle Behavior
1. User taps checkbox in list view
2. UI updates immediately (optimistic)
3. File write queued (batched for performance)
4. Markdown file updated: `- [ ]` → `- [x]` or vice versa
5. iCloud sync happens automatically in background

### 9. Data Synchronization

#### iCloud Integration
- App works with local filesystem (iCloud Drive folder mounted locally)
- No custom sync logic needed
- iCloud handles background sync to cloud + other devices
- **Write strategy**: Optimistic UI + queued writes (batch rapid changes)
- **Conflict resolution**: Last-write-wins (iCloud default)

#### File Operations
- **Read**: Parse markdown/YAML on demand (lazy loading)
- **Write**: Queue modifications, batch to reduce conflicts
- **Watch**: Monitor file system changes (FileManager observation)
- **No indexing**: Scan on demand (lazy loading approach)

#### Offline Support
- Fully functional offline (local file access)
- Changes queue if iCloud unavailable
- iOS handles sync when connectivity restored

### 10. Settings & Configuration

#### Folder Selection
- **Multi-select**: Choose one or more subfolders from iCloud Drive
- **Recursive**: Subfolders automatically included
- **Default save location**: One folder designated for new items
- **Persistent**: Configuration saved in app preferences (not vault)

#### Type Management
- View/edit/delete built-in types
- Create custom types
- Import/export type definitions (copy YAML)

#### Default LLM Prompt Template
- Editable in settings
- Used for "Copy LLM Prompt" feature
- Can be overridden per type

#### App Preferences
- Theme (light/dark/system)
- Default display style (list vs card)
- Quick capture default type
- Undo history length

### 11. Implementation Architecture

#### Two-Phase Development

**Phase 1: Core Engine (Ubuntu VPS, Swift on Linux)**
- Data models (Item, ListType, View, Filter)
- Markdown parser (checkbox extraction, frontmatter parsing)
- YAML handler (type definitions, view configs)
- File I/O layer (read/write/watch abstraction)
- Business logic (filtering, sorting, search, tag hierarchy)
- Comprehensive unit tests
- CLI prototype for validation

**Phase 2: iOS App (Mac, Xcode)**
- SwiftUI views (navigation, lists, forms, detail screens)
- Apple Intelligence integration (on-device extraction)
- iCloud Drive file access
- iOS-specific features (share sheet, shortcuts, widgets)
- UI tests and snapshot tests
- App packaging and distribution

#### Technology Stack

**Language & Frameworks:**
- Swift 5.9+
- SwiftUI (cross-platform UI)
- Swift Package Manager (dependencies)

**iOS-Specific:**
- Natural Language framework (text classification, entity extraction)
- Vision framework (OCR for photos)
- Core ML (on-device models)
- App Intents (Shortcuts integration)
- FileManager + iCloud APIs

**Third-Party (if needed):**
- Yams (YAML parsing) or custom parser
- Down or similar (markdown rendering if needed)

#### Code Organization

```
ListApp/
├── Core/                      # Phase 1 (Linux-compatible)
│   ├── Models/
│   │   ├── Item.swift
│   │   ├── ListType.swift
│   │   ├── View.swift
│   │   └── Filter.swift
│   ├── Parsers/
│   │   ├── MarkdownParser.swift
│   │   ├── YAMLParser.swift
│   │   └── TodoExtractor.swift
│   ├── FileSystem/
│   │   ├── FileManager.swift
│   │   ├── FileWatcher.swift
│   │   └── iCloudSync.swift
│   ├── Business/
│   │   ├── FilterEngine.swift
│   │   ├── SearchEngine.swift
│   │   └── TagHierarchy.swift
│   └── Tests/
├── iOS/                       # Phase 2 (macOS-only)
│   ├── Views/
│   ├── ViewModels/
│   ├── Intelligence/
│   │   ├── TypeDetector.swift
│   │   ├── PropertyExtractor.swift
│   │   └── PromptGenerator.swift
│   └── Tests/
└── Shared/
    └── Resources/
```

#### Design Patterns
- **MVVM**: ViewModels for business logic, Views for UI
- **Repository pattern**: FileManager abstraction for testability
- **Dependency injection**: Protocol-based for mocking
- **Combine/async-await**: For reactive data flow

### 12. Testing Strategy

#### Unit Tests (Phase 1)
- Markdown parsing edge cases (malformed syntax, missing fields)
- YAML parsing (type definitions, view configs, frontmatter)
- Filter logic (tag wildcards, date ranges, complex queries)
- Search functionality (text matching, ranking)
- File operations (read/write/watch)
- Tag hierarchy computation

#### UI Tests (Phase 2)
- Quick capture flow (input → detect → extract → save)
- Checkbox toggle (UI update → file write verification)
- View creation and filtering
- Navigation between screens
- Error state handling (parse errors, file write failures)

#### Integration Tests
- End-to-end: Create item → save → filter → toggle → verify file
- Multi-device sync simulation (write from two sources)
- Large vault performance (1000+ notes)

#### Snapshot Tests
- View rendering consistency
- Different display styles (list vs card)
- Error states (validation warnings, sync failures)

### 13. Performance Considerations

- **Lazy loading**: Parse files on demand, not upfront indexing
- **Batched writes**: Queue rapid changes, write once
- **Pagination**: Load items incrementally in long lists
- **Background parsing**: Parse files off main thread
- **Memory management**: Release parsed notes not in active views
- **File watching**: Efficient change detection, debounce rapid changes

### 14. Accessibility

- VoiceOver support (all interactive elements labeled)
- Dynamic Type (text scales with system settings)
- High contrast mode support
- Keyboard navigation (external keyboard support)
- Reduced motion (respect system preferences)

### 15. Security & Privacy

- **On-device processing**: No data sent to external servers
- **Local-only storage**: All data in user's iCloud Drive
- **No analytics**: No tracking or usage data collection
- **Sandboxed**: Standard iOS app sandbox
- **iCloud sync**: Uses Apple's encrypted sync

### 16. Future Considerations (Out of Scope for Phase 1 & 2)

- **MCP server**: Expose list data to LLMs via Model Context Protocol
- **Automated scheduling**: AI-based daily task suggestions
- **Linear integration**: Bi-directional sync with Linear tickets
- **Web interface**: Browser-based access on Mac
- **Recurring tasks**: Support for `🔁 every week` syntax
- **Rich text editing**: Markdown WYSIWYG editor
- **Collaboration**: Multi-user editing (conflicts beyond last-write-wins)
- **Custom input processors**: IMDb API, Goodreads API, book cover search
- **Mac app**: Native macOS version with menu bar integration

### 17. Design Decisions & Rationale

#### Why Obsidian-compatible markdown?
- **Portability**: Data isn't locked in proprietary format
- **Editability**: Can edit in any text editor or Obsidian itself
- **Longevity**: Plain text files will outlive any app
- **Interoperability**: Works with existing Obsidian plugins and workflows

#### Why on-device processing only?
- **Privacy**: No data leaves the device
- **Offline-first**: Works without internet
- **Performance**: No API latency
- **Cost**: No server infrastructure or API fees

#### Why tags instead of folders for organization?
- **Flexibility**: Items can belong to multiple categories
- **Hierarchy**: Nested tags provide structure without rigid folders
- **Filtering**: More powerful query capabilities
- **Future-proof**: Easy to reorganize without moving files

#### Why lazy loading instead of indexing?
- **Simplicity**: Less code, fewer failure modes
- **Real-time**: Always shows current file state
- **Memory**: Doesn't load entire vault into memory
- **Phase 1 feasibility**: Can defer optimization to Phase 2

---

## Success Metrics

### Phase 1 (Core Engine)
- ✅ All parsing functionality working correctly
- ✅ Test coverage >80%
- ✅ CLI demonstrates all features
- ✅ Performance targets met (scan <5s, filter <500ms)
- ✅ Documentation complete

### Phase 2 (iOS App)
- ✅ Native iOS app runs on iPhone and iPad
- ✅ Apple Intelligence integration functional
- ✅ iCloud Drive access working
- ✅ All UI flows implemented
- ✅ App Store ready

### User Success Metrics (Post-Launch)
- Users can manage 1000+ items smoothly
- Quick capture takes <10 seconds end-to-end
- Search returns results in <1 second
- App feels responsive (60fps scrolling)
- Zero data loss incidents

---

## Project Timeline

**Phase 1:** 10-12 weeks (Core Engine on Linux)  
**Phase 2:** 8-10 weeks (iOS app development)  
**Beta Testing:** 2-3 weeks  
**App Store Submission:** 1-2 weeks

**Total:** ~6 months to initial release

---

## Appendix

### Glossary

- **Item**: A single entry in any list (todo, book, movie, etc.)
- **List Type**: A template defining what fields an item can have
- **View**: A saved filter configuration for displaying items
- **Tag**: A hierarchical label for categorizing items
- **Frontmatter**: YAML metadata at the start of a markdown file
- **Vault**: An Obsidian term for a folder of markdown files

### References

- [Obsidian Documentation](https://help.obsidian.md/)
- [Apple Intelligence Frameworks](https://developer.apple.com/documentation/naturallanguage)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [YAML Specification](https://yaml.org/spec/)

---

**Document Version History:**
- v1.0 (2026-02-15): Initial specification from ideation phase
