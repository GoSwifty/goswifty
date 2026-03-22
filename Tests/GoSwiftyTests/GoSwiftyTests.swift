import XCTest
import Foundation
@testable import GoSwifty

final class GoSwiftyTests: XCTestCase {
    func testPercentageExtension() {
        let percentages = [2, 2].asPercentage

        XCTAssertEqual(percentages[0], 50.0, accuracy: 0.001)
        XCTAssertEqual(percentages[1], 50.0, accuracy: 0.001)
    }

    func testAIAgentReadinessAnalyzerDetectsSignals() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        try "GoSwifty".write(to: root.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        try "// swift package".write(to: root.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)

        try FileManager.default.createDirectory(at: root.appendingPathComponent(".github/workflows"), withIntermediateDirectories: true, attributes: nil)
        try "name: CI".write(to: root.appendingPathComponent(".github/workflows/ci.yml"), atomically: true, encoding: .utf8)

        try FileManager.default.createDirectory(at: root.appendingPathComponent("Tests"), withIntermediateDirectories: true, attributes: nil)
        try "import XCTest".write(to: root.appendingPathComponent("Tests/SampleTests.swift"), atomically: true, encoding: .utf8)

        try FileManager.default.createDirectory(at: root.appendingPathComponent("Sources"), withIntermediateDirectories: true, attributes: nil)
        try "let provider = \"OpenAI\"\nlet mode = \"agent\"\n".write(
            to: root.appendingPathComponent("Sources/Feature.swift"),
            atomically: true,
            encoding: .utf8
        )

        let report = AIAgentReadinessAnalyzer(paths: [root.path]).analyze()

        XCTAssertTrue(report.hasReadme)
        XCTAssertTrue(report.hasDependencyManifest)
        XCTAssertTrue(report.hasCiPipeline)
        XCTAssertTrue(report.hasTests)
        XCTAssertFalse(report.aiKeywordHits.isEmpty)
        XCTAssertGreaterThan(report.score, 0)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = root.appendingPathComponent("goswifty-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        return dir
    }

    static var allTests = [
        ("testPercentageExtension", testPercentageExtension),
        ("testAIAgentReadinessAnalyzerDetectsSignals", testAIAgentReadinessAnalyzerDetectsSignals),
    ]
}
