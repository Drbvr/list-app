import Foundation
import XCTest

#if canImport(Core)
import Core
#endif

final class PropertyValueTests: XCTestCase {

    func testPropertyValueTextCodable() throws {
        let value = PropertyValue.text("Hello World")
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PropertyValue.self, from: data)

        if case .text(let text) = decoded {
            XCTAssertEqual(text, "Hello World")
        } else {
            XCTFail("Expected text value, got \(decoded)")
        }
    }

    func testPropertyValueNumberCodable() throws {
        let value = PropertyValue.number(42.5)
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PropertyValue.self, from: data)

        if case .number(let number) = decoded {
            XCTAssertEqual(number, 42.5)
        } else {
            XCTFail("Expected number value, got \(decoded)")
        }
    }

    func testPropertyValueDateCodable() throws {
        let date = Date(timeIntervalSince1970: 1609459200)  // 2021-01-01
        let value = PropertyValue.date(date)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(PropertyValue.self, from: data)

        if case .date(let decodedDate) = decoded {
            XCTAssertEqual(decodedDate.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 1.0)
        } else {
            XCTFail("Expected date value, got \(decoded)")
        }
    }

    func testPropertyValueBoolCodable() throws {
        let value = PropertyValue.bool(true)
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PropertyValue.self, from: data)

        if case .bool(let bool) = decoded {
            XCTAssertEqual(bool, true)
        } else {
            XCTFail("Expected bool value, got \(decoded)")
        }
    }

    func testPropertyValueTextDecoding() throws {
        let json = """
        {"text": "Test Value"}
        """
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PropertyValue.self, from: json.data(using: .utf8)!)

        if case .text(let text) = decoded {
            XCTAssertEqual(text, "Test Value")
        } else {
            XCTFail("Expected text value")
        }
    }

    func testPropertyValueNumberDecoding() throws {
        let json = """
        {"number": 123.45}
        """
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PropertyValue.self, from: json.data(using: .utf8)!)

        if case .number(let number) = decoded {
            XCTAssertEqual(number, 123.45)
        } else {
            XCTFail("Expected number value")
        }
    }

    func testPropertyValueBoolDecoding() throws {
        let json = """
        {"bool": false}
        """
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PropertyValue.self, from: json.data(using: .utf8)!)

        if case .bool(let bool) = decoded {
            XCTAssertEqual(bool, false)
        } else {
            XCTFail("Expected bool value")
        }
    }

    func testPropertyValueDecodingInvalid() throws {
        let json = """
        {"invalid": "value"}
        """
        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(PropertyValue.self, from: json.data(using: .utf8)!))
    }
}
