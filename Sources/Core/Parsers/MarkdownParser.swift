import Foundation

/// Protocol for parsing markdown content into items
public protocol MarkdownParser {
    func parseTodos(from content: String, sourceFile: String) -> [Item]
}

/// Obsidian-compatible todo parser for markdown files
public class ObsidianTodoParser: MarkdownParser {

    public init() {}

    /// Parses markdown content and extracts todo items
    public func parseTodos(from content: String, sourceFile: String) -> [Item] {
        let lines = content.components(separatedBy: .newlines)
        var items: [Item] = []
        var currentTodo: (checkbox: Substring, text: String)?
        var inCodeBlock = false

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Track code blocks
            if trimmedLine.hasPrefix("```") {
                inCodeBlock.toggle()
                continue
            }

            // Skip if in code block
            if inCodeBlock {
                continue
            }

            // Check if this is a todo line
            if let checkboxMatch = extractCheckbox(from: line) {
                // If we have a previous todo, add it
                if let (checkbox, text) = currentTodo {
                    if let item = createItem(from: String(checkbox), text: text, sourceFile: sourceFile) {
                        items.append(item)
                    }
                }

                // Start new todo
                let todoText = extractTodoText(from: line)
                currentTodo = (checkboxMatch, todoText)
            } else if let (checkbox, text) = currentTodo {
                // Continue multi-line todo
                if !trimmedLine.isEmpty {
                    currentTodo = (checkbox, text + "\n" + trimmedLine)
                }
            }
        }

        // Add last todo
        if let (checkbox, text) = currentTodo {
            if let item = createItem(from: String(checkbox), text: text, sourceFile: sourceFile) {
                items.append(item)
            }
        }

        return items
    }

    /// Extracts checkbox from a line (returns "[ ]" or "[x]" if found)
    private func extractCheckbox(from line: String) -> Substring? {
        // Match "- [ ]", "- [x]", "* [ ]", "* [x]"
        let pattern = "^\\s*[-*]\\s+\\[(.?)\\]"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(line.startIndex..., in: line)
            if let match = regex.firstMatch(in: line, range: range) {
                if let checkboxRange = Range(match.range(at: 0), in: line) {
                    let checkbox = line[checkboxRange]
                    // Extract just the bracket part
                    if let bracketStart = checkbox.firstIndex(of: "["),
                       let bracketEnd = checkbox.firstIndex(of: "]") {
                        let nextIndex = checkbox.index(after: bracketEnd)
                        if nextIndex <= checkbox.endIndex {
                            return checkbox[bracketStart..<nextIndex]
                        }
                    }
                }
            }
        }
        return nil
    }

    /// Extracts todo text after the checkbox
    private func extractTodoText(from line: String) -> String {
        // Remove the checkbox part and return the text
        let pattern = "^\\s*[-*]\\s+\\[.?\\]\\s*"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(line.startIndex..., in: line)
            let result = regex.stringByReplacingMatches(in: line, range: range, withTemplate: "")
            return result
        }
        return line
    }

    /// Creates an Item from parsed todo components
    private func createItem(from checkbox: String, text: String, sourceFile: String) -> Item? {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil  // Skip empty checkboxes
        }

        let completed = checkbox.contains("x") || checkbox.contains("X")
        let title = extractTitle(from: text)
        let tags = extractTags(from: text)
        let dueDate = extractDate(from: text)
        let priority = extractPriority(from: text)

        var properties: [String: PropertyValue] = [:]

        if let priority = priority {
            properties["priority"] = PropertyValue.text(priority)
        }

        if let dueDate = dueDate {
            properties["dueDate"] = PropertyValue.date(dueDate)
        }

        let item = Item(
            type: "todo",
            title: title,
            properties: properties,
            tags: tags,
            completed: completed,
            sourceFile: sourceFile
        )

        return item
    }

    /// Extracts clean title (removes metadata)
    private func extractTitle(from text: String) -> String {
        var result = text

        // Remove dates
        result = result.replacingOccurrences(of: "📅\\s*\\d{4}-\\d{2}-\\d{2}(?:T\\d{2}:\\d{2})?", with: "", options: .regularExpression)

        // Remove priority emojis
        result = result.replacingOccurrences(of: "[⏫🔼🔽]", with: "", options: .regularExpression)

        // Remove tags
        result = result.replacingOccurrences(of: "#[\\w/]+", with: "", options: .regularExpression)

        return result.trimmingCharacters(in: .whitespaces)
    }

    /// Extracts tags from text
    private func extractTags(from text: String) -> [String] {
        var tags: [String] = []
        let pattern = "#([\\w/]+)"

        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: range)

            for match in matches {
                if let tagRange = Range(match.range(at: 1), in: text) {
                    let tag = String(text[tagRange])
                    tags.append(tag)
                }
            }
        }

        return tags
    }

    /// Extracts due date from text
    private func extractDate(from text: String) -> Date? {
        // Look for 📅 YYYY-MM-DD or 📅 YYYY-MM-DDTHH:MM
        let pattern = "📅\\s*(\\d{4}-\\d{2}-\\d{2})(?:T(\\d{2}):(\\d{2}))?"

        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, range: range) {
                if let dateRange = Range(match.range(at: 1), in: text) {
                    let dateString = String(text[dateRange])

                    // Try to parse date
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withFullDate]

                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
            }
        }

        return nil
    }

    /// Extracts priority from text
    private func extractPriority(from text: String) -> String? {
        if text.contains("⏫") {
            return "high"
        } else if text.contains("🔼") {
            return "medium"
        } else if text.contains("🔽") {
            return "low"
        }
        return nil
    }
}
