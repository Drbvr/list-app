# ListApp iOS UI Scaffolding

SwiftUI views and mock data for the List Management iOS app. These files are designed to be added to an Xcode project that imports the `Core` library.

## Integration with Xcode

### 1. Create iOS Project

1. Open Xcode
2. File > New > Project > iOS > App
3. Product Name: `ListApp`
4. Interface: SwiftUI
5. Language: Swift
6. Minimum Deployment: iOS 17.0

### 2. Add Core as Local Package Dependency

1. In Xcode, File > Add Package Dependencies
2. Click "Add Local..."
3. Select the root of this repository (the directory containing `Package.swift`)
4. Add the `Core` library to your app target

### 3. Add UI Files

1. In Xcode, right-click your app target in the navigator
2. Add Files to "ListApp"
3. Select all files from this `ListApp/` directory
4. Ensure "Copy items if needed" is unchecked (reference in place)
5. Ensure your app target is checked

### 4. Remove Generated ContentView

Delete the auto-generated `ContentView.swift` from the Xcode project template — this directory provides its own `ContentView.swift`.

### 5. Build and Run

Select an iPhone simulator (iPhone 16 recommended) and press Cmd+R.

## Directory Structure

```
ListApp/
├── App/ListAppApp.swift          # @main entry point
├── ViewModels/AppState.swift     # Central app state (uses Core engine)
├── Views/
│   ├── ContentView.swift         # TabView with 5 tabs
│   ├── SavedViewsListView.swift  # Saved views list
│   ├── ItemListView.swift        # Item list with swipe actions
│   ├── ItemDetailView.swift      # Item detail (properties, tags, metadata)
│   ├── FilterView.swift          # Custom filter builder
│   ├── TagBrowserView.swift      # Hierarchical tag browser
│   ├── SearchView.swift          # Full-text search
│   └── SettingsView.swift        # Settings (stubs)
├── Components/
│   ├── ItemRowView.swift         # Reusable item row
│   ├── TagChipView.swift         # Tag chip
│   └── FlowLayout.swift          # Flow layout for tags
└── Services/
    └── FileSystemManager.swift   # File system stub (mock data)
```

## Architecture

- **@Observable** pattern (iOS 17+) for state management
- **AppState** wraps Core's `ItemFilterEngine`, `FullTextSearchEngine`, and `TagHierarchy`
- All models come from `Core` — no duplicated types
- Mock data via `Core.MockData` for development/previews
- `FileSystemManager` is a stub ready for real iCloud Drive integration
