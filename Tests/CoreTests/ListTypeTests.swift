import Foundation
import XCTest

#if canImport(Core)
import Core
#endif

final class ListTypeTests: XCTestCase {

    func testFieldTypeEnum() {
        XCTAssertEqual(FieldType.text.rawValue, "text")
        XCTAssertEqual(FieldType.number.rawValue, "number")
        XCTAssertEqual(FieldType.date.rawValue, "date")
    }

    func testFieldDefinitionInitialization() {
        let field = FieldDefinition(
            name: "title",
            type: .text,
            required: true
        )

        XCTAssertEqual(field.name, "title")
        XCTAssertEqual(field.type, .text)
        XCTAssertEqual(field.required, true)
        XCTAssertNil(field.min)
        XCTAssertNil(field.max)
    }

    func testFieldDefinitionWithValidation() {
        let field = FieldDefinition(
            name: "rating",
            type: .number,
            required: false,
            min: 1.0,
            max: 5.0
        )

        XCTAssertEqual(field.name, "rating")
        XCTAssertEqual(field.type, .number)
        XCTAssertEqual(field.min, 1.0)
        XCTAssertEqual(field.max, 5.0)
    }

    func testFieldDefinitionCodable() throws {
        let field = FieldDefinition(
            name: "priority",
            type: .number,
            required: true,
            min: 1.0,
            max: 3.0
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(field)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FieldDefinition.self, from: data)

        XCTAssertEqual(decoded.name, field.name)
        XCTAssertEqual(decoded.type, field.type)
        XCTAssertEqual(decoded.required, field.required)
        XCTAssertEqual(decoded.min, field.min)
        XCTAssertEqual(decoded.max, field.max)
    }

    func testListTypeInitialization() {
        let listType = ListType(name: "Todo")

        XCTAssertEqual(listType.name, "Todo")
        XCTAssertEqual(listType.fields.count, 0)
        XCTAssertNil(listType.llmExtractionPrompt)
    }

    func testListTypeWithFields() {
        let fields = [
            FieldDefinition(name: "title", type: .text, required: true),
            FieldDefinition(name: "dueDate", type: .date, required: false),
            FieldDefinition(name: "priority", type: .number, required: false, min: 1.0, max: 3.0)
        ]

        let listType = ListType(
            name: "Todo",
            fields: fields,
            llmExtractionPrompt: "Extract todos from text"
        )

        XCTAssertEqual(listType.name, "Todo")
        XCTAssertEqual(listType.fields.count, 3)
        XCTAssertEqual(listType.llmExtractionPrompt, "Extract todos from text")
    }

    func testListTypeCodable() throws {
        let fields = [
            FieldDefinition(name: "title", type: .text, required: true),
            FieldDefinition(name: "rating", type: .number, required: false, min: 1.0, max: 5.0)
        ]

        let originalType = ListType(
            name: "Book",
            fields: fields,
            llmExtractionPrompt: "Extract book info"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalType)

        let decoder = JSONDecoder()
        let decodedType = try decoder.decode(ListType.self, from: data)

        XCTAssertEqual(decodedType.name, originalType.name)
        XCTAssertEqual(decodedType.fields.count, 2)
        XCTAssertEqual(decodedType.llmExtractionPrompt, originalType.llmExtractionPrompt)
    }

    func testListTypeJSON() throws {
        let json = """
        {
            "name": "Book",
            "fields": [
                {
                    "name": "title",
                    "type": "text",
                    "required": true,
                    "min": null,
                    "max": null
                },
                {
                    "name": "rating",
                    "type": "number",
                    "required": false,
                    "min": 1.0,
                    "max": 5.0
                }
            ],
            "llmExtractionPrompt": "Extract book info"
        }
        """

        let decoder = JSONDecoder()
        let listType = try decoder.decode(ListType.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(listType.name, "Book")
        XCTAssertEqual(listType.fields.count, 2)
        XCTAssertEqual(listType.fields[0].name, "title")
        XCTAssertEqual(listType.fields[1].min, 1.0)
        XCTAssertEqual(listType.fields[1].max, 5.0)
    }

    func testFieldDefinitionNumberValidation() {
        let field = FieldDefinition(
            name: "score",
            type: .number,
            required: true,
            min: 0.0,
            max: 100.0
        )

        XCTAssertEqual(field.min, 0.0)
        XCTAssertEqual(field.max, 100.0)
    }

    func testMultipleFieldTypes() {
        let textField = FieldDefinition(name: "description", type: .text, required: false)
        let numberField = FieldDefinition(name: "quantity", type: .number, required: false)
        let dateField = FieldDefinition(name: "deadline", type: .date, required: false)

        XCTAssertEqual(textField.type, .text)
        XCTAssertEqual(numberField.type, .number)
        XCTAssertEqual(dateField.type, .date)
    }
}
