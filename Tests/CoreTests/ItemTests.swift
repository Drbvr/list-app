import Foundation
import XCTest

#if canImport(Core)
import Core
#endif

final class ItemTests: XCTestCase {

    func testItemInitialization() {
        let item = Item(
            type: "todo",
            title: "Test Task",
            sourceFile: "/path/to/file.md"
        )

        XCTAssertEqual(item.type, "todo")
        XCTAssertEqual(item.title, "Test Task")
        XCTAssertEqual(item.sourceFile, "/path/to/file.md")
        XCTAssertEqual(item.completed, false)
        XCTAssertEqual(item.tags, [])
        XCTAssertEqual(item.properties, [:])
    }

    func testItemWithProperties() {
        let properties = [
            "priority": PropertyValue.text("high"),
            "rating": PropertyValue.number(4.5)
        ]
        let item = Item(
            type: "book",
            title: "Swift Programming",
            properties: properties,
            sourceFile: "/books/swift.md"
        )

        XCTAssertEqual(item.properties.count, 2)
        if case .text(let priority) = item.properties["priority"] {
            XCTAssertEqual(priority, "high")
        } else {
            XCTFail("Expected text value for priority")
        }
    }

    func testItemWithTags() {
        let tags = ["work/backend", "urgent", "linear"]
        let item = Item(
            type: "todo",
            title: "Fix auth bug",
            tags: tags,
            sourceFile: "/work.md"
        )

        XCTAssertEqual(item.tags.count, 3)
        XCTAssert(item.tags.contains("work/backend"))
        XCTAssert(item.tags.contains("urgent"))
    }

    func testItemCodable() throws {
        let originalItem = Item(
            id: UUID(),
            type: "todo",
            title: "Test Task",
            tags: ["work/backend", "urgent"],
            completed: false,
            sourceFile: "/test.md"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(originalItem)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedItem = try decoder.decode(Item.self, from: data)

        XCTAssertEqual(decodedItem.id, originalItem.id)
        XCTAssertEqual(decodedItem.type, originalItem.type)
        XCTAssertEqual(decodedItem.title, originalItem.title)
        XCTAssertEqual(decodedItem.tags, originalItem.tags)
        XCTAssertEqual(decodedItem.completed, originalItem.completed)
        XCTAssertEqual(decodedItem.sourceFile, originalItem.sourceFile)
    }

    func testItemCompleted() {
        let completedItem = Item(
            type: "todo",
            title: "Completed Task",
            completed: true,
            sourceFile: "/done.md"
        )

        XCTAssertEqual(completedItem.completed, true)
    }

    func testItemHierarchicalTags() {
        let tags = ["work/backend/api", "work/backend/database", "personal/learning"]
        let item = Item(
            type: "todo",
            title: "Task",
            tags: tags,
            sourceFile: "/file.md"
        )

        XCTAssertEqual(item.tags.count, 3)
        XCTAssert(item.tags.contains("work/backend/api"))
        XCTAssert(item.tags.contains("work/backend/database"))
        XCTAssert(item.tags.contains("personal/learning"))
    }

    func testItemIdentifiable() {
        let id = UUID()
        let item = Item(
            id: id,
            type: "todo",
            title: "Test",
            sourceFile: "/file.md"
        )

        XCTAssertEqual(item.id, id)
    }

    func testItemWithComplexProperties() throws {
        let date = Date(timeIntervalSince1970: 1609459200)
        let properties: [String: PropertyValue] = [
            "dueDate": PropertyValue.date(date),
            "priority": PropertyValue.text("high"),
            "estimate": PropertyValue.number(5.0),
            "isBlocked": PropertyValue.bool(false)
        ]

        let item = Item(
            type: "todo",
            title: "Complex Task",
            properties: properties,
            sourceFile: "/complex.md"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(item)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Item.self, from: data)

        XCTAssertEqual(decoded.properties.count, 4)
        XCTAssert(decoded.properties.keys.contains("dueDate"))
        XCTAssert(decoded.properties.keys.contains("priority"))
    }

    func testItemJSON() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "type": "todo",
            "title": "Review PR",
            "properties": {"priority": {"text": "high"}},
            "tags": ["work/backend"],
            "completed": false,
            "sourceFile": "/work.md",
            "createdAt": "2024-01-01T00:00:00Z",
            "updatedAt": "2024-01-01T00:00:00Z"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let item = try decoder.decode(Item.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(item.type, "todo")
        XCTAssertEqual(item.title, "Review PR")
        XCTAssert(item.tags.contains("work/backend"))
    }
}
