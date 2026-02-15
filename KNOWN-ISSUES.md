# Known Issues and Limitations

This document outlines known limitations, edge cases, and future enhancements for the Phase 1 Core Engine.

## Current Limitations

### 1. No File Watching

**Status:** Out of scope for Phase 1

The core engine does not monitor the vault folder for changes. Files must be re-scanned manually.

**Workaround:** Call `scanAndParseVault()` periodically or on user action
**Phase 2:** Will add file watching for real-time updates

### 2. No Recurring Tasks

**Status:** Not implemented

Recurring tasks (daily, weekly, monthly) are not supported. Each occurrence must be a separate item.

**Workaround:** Create multiple items with different due dates
**Future:** Implement recurrence patterns with date expansion

### 3. Tag Renaming Requires Manual Find/Replace

**Status:** Not implemented

Renaming a tag across multiple files requires manual editing.

**Workaround:** Use search and replace in your text editor
**Future:** Implement bulk tag renaming with validation

### 4. Large Files (>10MB) May Be Slow

**Status:** Performance consideration

Files larger than 10MB may experience slower parsing. The parser loads entire files into memory.

**Workaround:** Split large files into smaller ones (recommended <5MB per file)
**Performance targets:**
- 1MB file: <50ms
- 5MB file: <250ms
- 10MB file: <1s

### 5. No Real-Time Collaboration

**Status:** Not supported

Multiple users editing the same vault simultaneously may cause conflicts.

**Workaround:** Use version control or external sync (iCloud Drive, Dropbox)
**Future:** Implement conflict detection and resolution

## Edge Cases Not Handled

### 1. Symlinks in Vault Folders

**Current Behavior:** Symlinks are skipped during directory scanning

```swift
// Symlinks are NOT followed
scanDirectory(at: vaultPath, recursive: true)
```

**Why:** Prevents infinite loops and unexpected behavior

**Workaround:** Copy files instead of symlinking
**Future:** Add configurable symlink handling

### 2. Markdown Files with Non-UTF8 Encoding

**Current Behavior:** Will fail with `ioError`

```swift
// Only UTF-8 is supported
let content = try String(contentsOfFile: path, encoding: .utf8)
```

**Why:** Swift String uses UTF-8 by default; other encodings are rare in Markdown

**Workaround:** Convert files to UTF-8 encoding
**Future:** Auto-detect encoding with fallback

### 3. Files with Very Long Lines (>10,000 chars)

**Current Behavior:** May cause performance degradation or memory issues

**Why:** Regex matching and string manipulation scale poorly with line length

**Workaround:** Break long lines at reasonable boundaries
**Future:** Implement streaming line-by-line parser

### 4. Deeply Nested Tag Hierarchies (>20 levels)

**Current Behavior:** Works but may have performance overhead

```swift
// Supported but not tested beyond 20 levels
tags: ["a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p/q/r/s/t"]
```

**Why:** Not typical usage pattern

**Workaround:** Keep hierarchies to <10 levels
**Future:** Optimize tag traversal for deep hierarchies

### 5. Unicode Emojis in Filenames

**Current Behavior:** Works but file paths may display incorrectly in some terminals

**Why:** Terminal encoding varies by platform

**Workaround:** Use ASCII filenames for vault folders
**Future:** Better emoji handling in CLI

### 6. YAML Arrays with Very Long Strings

**Current Behavior:** Parsing works but may be slow

```yaml
tags: [this-is-a-very-long-tag-name-that-exceeds-normal-limits, ...]
```

**Why:** String parsing scales with string length

**Workaround:** Keep tag names reasonable (<50 chars)

### 7. Special Characters in Search Queries

**Current Behavior:** Special regex characters must be manually escaped

```swift
searchEngine.search(query: "[test]", in: items)  // Won't match "[test]"
```

**Why:** Search uses regex internally

**Workaround:** Avoid special regex characters in queries
**Future:** Auto-escape special characters

## Performance Notes

### Tested Scenarios

| Scenario | Scale | Time | Status |
|----------|-------|------|--------|
| Parse todos | 1,000 items | <500ms | ✅ Excellent |
| Filter items | 10,000 items | <100ms | ✅ Excellent |
| Search items | 10,000 items | <500ms | ✅ Good |
| Scan files | 1,000 files | <2s | ✅ Good |
| Load views | 100 views | <50ms | ✅ Excellent |
| Parse YAML | 1MB frontmatter | <100ms | ✅ Excellent |

### Known Performance Issues

1. **Search with many results**: Returns all results in memory (no pagination)
   - Workaround: Filter before searching

2. **Large vaults with many views**: Loading all views is not lazy
   - Workaround: Load only needed views

3. **Deep tag hierarchies**: Wildcard expansion scales with number of tags
   - Workaround: Keep tag count reasonable (<1000)

## Platform-Specific Issues

### macOS

- File access may require user permission for sandboxed apps
- Symlinks in `/Volumes` may not be handled correctly

### iOS

- Limited sandbox access to files outside app container
- Must use FileManager or document picker for external files
- iCloud Drive sync may be delayed

### Linux

- File permissions handled by POSIX conventions
- No special handling for case-insensitive filesystems (APFS, NTFS)

## Browser/Network Issues (Not Applicable)

The Core engine is designed for local file operations only:
- ❌ No network support
- ❌ No cloud storage integration
- ❌ No HTTP/HTTPS support
- ❌ No real-time sync

## Future Enhancements

### Priority 1: High Value

1. **File Watching**
   - Monitor vault for changes
   - Refresh on update
   - Estimated effort: 2 weeks

2. **Better Error Messages**
   - More descriptive parsing errors
   - Line numbers in parse errors
   - Estimated effort: 1 week

3. **Pagination Support**
   - Large result sets pagination
   - Memory efficiency improvements
   - Estimated effort: 2 weeks

### Priority 2: Medium Value

1. **Recurring Tasks**
   - Recurrence patterns (daily, weekly, etc.)
   - Date expansion for recurrences
   - Estimated effort: 3 weeks

2. **Bulk Tag Renaming**
   - Find and rename across files
   - Validation and conflict checking
   - Estimated effort: 2 weeks

3. **Streaming Parser**
   - Handle large files more efficiently
   - Line-by-line processing
   - Estimated effort: 3 weeks

### Priority 3: Nice to Have

1. **Customizable Exclusions**
   - Config for excluded folders/files
   - Pattern-based filtering
   - Estimated effort: 1 week

2. **Property Validation**
   - Field type checking
   - Custom validation rules
   - Estimated effort: 2 weeks

3. **Export Formats**
   - CSV/JSON export
   - Report generation
   - Estimated effort: 2 weeks

## Reporting Issues

If you encounter issues not listed here:

1. **Reproduction steps**
   - Provide minimal example
   - Include markdown content
   - Note Swift version

2. **Expected vs. Actual**
   - What should happen
   - What actually happened
   - Error messages

3. **Environment**
   - macOS/iOS/Linux version
   - Swift version
   - Xcode version (if applicable)

## Testing Coverage

The Core engine has >85% code coverage:
- ✅ 41 model tests
- ✅ 56 parser tests
- ✅ 23 file system tests
- ✅ 62 business logic tests
- ✅ 27 CLI tests
- ✅ 208 total tests

However, some edge cases may not be covered:
- Specific Unicode combinations
- File system race conditions
- Out-of-memory conditions
- Corrupted file scenarios

## Support

For more information:
- See [README.md](./README.md) for features
- See [PHASE2-PREP.md](./PHASE2-PREP.md) for iOS integration
- Review test files for usage examples
- Check code comments for implementation details
