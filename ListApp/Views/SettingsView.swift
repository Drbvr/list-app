import SwiftUI
import Core

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTheme = "system"
    @State private var defaultDisplayStyle = DisplayStyle.list

    var body: some View {
        Form {
            Section("Folders") {
                HStack {
                    Image(systemName: "folder.badge.plus")
                        .foregroundColor(.accentColor)
                    Text("Select Folders from iCloud Drive")
                        .foregroundStyle(.secondary)
                }

                ForEach(["Work", "Personal", "Books"], id: \.self) { folder in
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.blue)
                        Text(folder)
                        Spacer()
                        Image(systemName: "checkmark")
                            .foregroundStyle(.green)
                    }
                }
            }

            Section("List Types") {
                ForEach(appState.listTypes, id: \.name) { listType in
                    HStack {
                        Text(listType.name)
                        Spacer()
                        Text("\(listType.fields.count) fields")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Appearance") {
                Picker("Theme", selection: $selectedTheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                Picker("Default Display", selection: $defaultDisplayStyle) {
                    Text("List").tag(DisplayStyle.list)
                    Text("Card").tag(DisplayStyle.card)
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Core.version)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Items")
                    Spacer()
                    Text("\(appState.items.count)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Saved Views")
                    Spacer()
                    Text("\(appState.savedViews.count)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}
