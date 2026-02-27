# ListApp Bug Report & Test Plan

## Overview
Testing the app via simulator to identify bugs and improvements. This document tracks issues found and fixes implemented.

---

## Issues Identified

### 🐛 BUG #1: Todo Completion Not Persisted to Files
**Severity:** HIGH - Data Loss Risk
**Description:** When user toggles todo completion in the UI, `AppState.toggleCompletion()` updates the in-memory item, but doesn't call `AppFileSystemManager.toggleTodoCompletion()` to persist the change to the markdown file.

**Current Code (AppState.swift:84-88):**
```swift
func toggleCompletion(for item: Item) {
    if let index = items.firstIndex(where: { $0.id == item.id }) {
        items[index].completed.toggle()
        items[index].updatedAt = Date()
    }
}
```

**Impact:**
- Changes are lost when app restarts
- User believes they saved data but it's only in memory

**Fix Required:** Call `AppFileSystemManager.toggleTodoCompletion()` inside `toggleCompletion()`

---

### 🐛 BUG #2: Search Returns Empty When Query is Cleared
**Severity:** MEDIUM - UX Issue
**Description:** `AppState.searchItems()` returns empty array when query is empty (guard statement on line 108).

**Current Code (AppState.swift:107-111):**
```swift
func searchItems(query: String) -> [Item] {
    guard !query.isEmpty else { return [] }  // ← Always returns empty for empty query
    let results = searchEngine.search(query: query, in: items)
    return results.map { $0.item }
}
```

**Impact:**
- SearchView can't show "all items" when search field is cleared
- User can't see available items without typing

**Fix Required:** Return all items when query is empty

---

### ⚠️ IMPROVEMENT #1: Synchronous File I/O on Main Thread
**Severity:** MEDIUM - Performance
**Description:** `AppState.init()` uses synchronous file I/O which can block the UI thread during app launch if vault has many files.

**Current Code (AppState.swift:15-42):**
```swift
init() {
    // Synchronous file operations here
    if case .success(let filePaths) = coreFileSystem.scanDirectory(...) {
        for filePath in filePaths {
            if case .success(let content) = coreFileSystem.readFile(at: filePath) {
                // Parsing happens here
            }
        }
    }
}
```

**Impact:**
- App may appear to freeze on launch with large vaults
- User sees unresponsive UI

**Fix Required:** Move to async/await pattern with a loading state

---

### ⚠️ IMPROVEMENT #2: ItemRowView Completion Button Behavior
**Severity:** LOW - UI Polish
**Description:** ItemRowView has a completion toggle button, but it's not clear if it persists or if user needs to use swipe actions.

**Impact:**
- User confusion about how to save changes
- Inconsistent interaction pattern

**Fix Required:** Document or consolidate completion toggle methods

---

## Test Results

### Test Run #1 - Feb 27, 2026 20:30
- ✅ App launches without crash
- ✅ 5 main tabs visible (Views, Filter, Tags, Search, Settings)
- ✅ Saved Views list loads
- ❌ Todo completion toggle doesn't persist (BUG #1)
- ❌ Search with empty query returns no items (BUG #2)
- ⚠️ App launch feels sluggish with 11 items (IMPROVEMENT #1)

---

## Fix Priority

1. **HIGH:** BUG #1 - Persist todo completion to files
2. **MEDIUM:** BUG #2 - Allow searching empty query to show all items
3. **MEDIUM:** IMPROVEMENT #1 - Async file loading on startup
4. **LOW:** IMPROVEMENT #2 - UI polish for completion toggle

---

## Next Steps
- [ ] Implement BUG #1 fix: Modify `AppState.toggleCompletion()` to call `AppFileSystemManager`
- [ ] Implement BUG #2 fix: Modify `AppState.searchItems()` to return all items for empty query
- [ ] Implement IMPROVEMENT #1: Convert AppState init to async with loading indicator
- [ ] Run tests to verify fixes
- [ ] Commit changes with test results
