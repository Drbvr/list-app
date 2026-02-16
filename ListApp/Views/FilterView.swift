import SwiftUI
import Core

struct FilterView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTags: Set<String> = []
    @State private var selectedTypes: Set<String> = []
    @State private var completionFilter: CompletionFilter = .all

    private enum CompletionFilter: String, CaseIterable {
        case all = "All"
        case incomplete = "Incomplete"
        case completed = "Completed"
    }

    private var currentFilters: ViewFilters {
        ViewFilters(
            tags: selectedTags.isEmpty ? nil : Array(selectedTags),
            itemTypes: selectedTypes.isEmpty ? nil : Array(selectedTypes),
            completed: completionFilter == .all ? nil : completionFilter == .completed
        )
    }

    private var filteredItems: [Item] {
        appState.filteredItems(with: currentFilters)
    }

    var body: some View {
        Form {
            Section("Item Types") {
                ForEach(appState.itemTypeNames, id: \.self) { type in
                    Toggle(type.capitalized, isOn: Binding(
                        get: { selectedTypes.contains(type) },
                        set: { if $0 { selectedTypes.insert(type) } else { selectedTypes.remove(type) } }
                    ))
                }
            }

            Section("Status") {
                Picker("Completion", selection: $completionFilter) {
                    ForEach(CompletionFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Tags") {
                ForEach(appState.allTags, id: \.self) { tag in
                    Toggle(isOn: Binding(
                        get: { selectedTags.contains(tag) },
                        set: { if $0 { selectedTags.insert(tag) } else { selectedTags.remove(tag) } }
                    )) {
                        TagChipView(tag: tag)
                    }
                }
            }

            Section {
                NavigationLink {
                    ItemListView(
                        title: "Filtered Results",
                        items: filteredItems,
                        displayStyle: .list
                    )
                } label: {
                    HStack {
                        Text("View Results")
                        Spacer()
                        Text("\(filteredItems.count) items")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Custom Filter")
    }
}
