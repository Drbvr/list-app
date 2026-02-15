import Foundation

/// Represents a saved view configuration
public struct SavedView: Codable {
    public let name: String
    public var filters: ViewFilters
    public var displayStyle: DisplayStyle

    public init(
        name: String,
        filters: ViewFilters = ViewFilters(),
        displayStyle: DisplayStyle = .list
    ) {
        self.name = name
        self.filters = filters
        self.displayStyle = displayStyle
    }
}

/// Represents filters for viewing items
public struct ViewFilters: Codable {
    public var tags: [String]?  // Support wildcards like "work/*"
    public var itemTypes: [String]?
    public var dueBefore: Date?
    public var dueAfter: Date?
    public var completed: Bool?
    public var folders: [String]?

    public init(
        tags: [String]? = nil,
        itemTypes: [String]? = nil,
        dueBefore: Date? = nil,
        dueAfter: Date? = nil,
        completed: Bool? = nil,
        folders: [String]? = nil
    ) {
        self.tags = tags
        self.itemTypes = itemTypes
        self.dueBefore = dueBefore
        self.dueAfter = dueAfter
        self.completed = completed
        self.folders = folders
    }
}

/// Represents how a view should be displayed
public enum DisplayStyle: String, Codable {
    case list
    case card
}
