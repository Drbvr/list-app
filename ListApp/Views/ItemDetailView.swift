import SwiftUI
import Core

struct ItemDetailView: View {
    @Environment(AppState.self) private var appState
    let item: Item

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Type")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(item.type.capitalized)
                }

                if item.type == "todo" {
                    HStack {
                        Text("Status")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(item.completed ? "Completed" : "Incomplete")
                            .foregroundStyle(item.completed ? .green : .orange)
                    }
                }
            }

            if !item.properties.isEmpty {
                Section("Properties") {
                    ForEach(Array(item.properties.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                        HStack {
                            Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                                .foregroundStyle(.secondary)
                            Spacer()
                            propertyValueView(value)
                        }
                    }
                }
            }

            if !item.tags.isEmpty {
                Section("Tags") {
                    FlowLayout(spacing: 8) {
                        ForEach(item.tags, id: \.self) { tag in
                            TagChipView(tag: tag)
                        }
                    }
                }
            }

            Section("Metadata") {
                HStack {
                    Text("Source File")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(item.sourceFile)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Created")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(item.createdAt, style: .date)
                }
                HStack {
                    Text("Updated")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(item.updatedAt, style: .date)
                }
            }
        }
        .navigationTitle(item.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            if item.type == "todo" {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        appState.toggleCompletion(for: item)
                    } label: {
                        Image(systemName: item.completed
                              ? "checkmark.circle.fill"
                              : "circle")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func propertyValueView(_ value: PropertyValue) -> some View {
        switch value {
        case .text(let text):
            Text(text)
        case .number(let number):
            Text(String(format: number.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", number))
        case .date(let date):
            Text(date, style: .date)
        case .bool(let bool):
            Image(systemName: bool ? "checkmark" : "xmark")
                .foregroundStyle(bool ? .green : .red)
        }
    }
}
