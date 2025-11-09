import XCTest
import SwiftTreeSitter
import TreeSitterEfus

final class TreeSitterEfusTests: XCTestCase {
    func testCanLoadGrammar() throws {
        let parser = Parser()
        let language = Language(language: tree_sitter_efus())
        XCTAssertNoThrow(try parser.setLanguage(language),
                         "Error loading Efus template parser grammar")
    }
}
