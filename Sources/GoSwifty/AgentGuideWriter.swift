//
//  AgentGuideWriter.swift
//
//
//  Created by Codex on 3/22/26.
//

import Foundation

enum AgentGuideWriter {
    static func makeMarkdown(report: AIAgentReadinessReport, analyzedPath: String) -> String {
        let workflowCommands = detectWorkflowCommands(for: analyzedPath)
        let commandBlock = workflowCommands.map { "- `\($0)`" }.joined(separator: "\n")
        let aiSignals = report.aiKeywordHits.keys.sorted().prefix(10).map { "- `\($0)`" }.joined(separator: "\n")

        return """
        # AGENTS.md

        ## Mission
        Preserve GoSwifty's original migration analysis features and extend the project with practical AI and AI-agent tooling.

        ## Scope
        - Keep existing command behavior stable, especially `analyze`.
        - Add new features behind new commands (`ai ...`) to avoid regressions.
        - Prefer small, test-backed increments over broad refactors.

        ## Project Snapshot
        - Current AI readiness score: \(report.score)/100 (\(report.level))
        - Files scanned by scaffold source: \(report.totalFiles)
        - Target path: `\(analyzedPath)`

        ## Local Workflow
        \(commandBlock)

        ## Agent Working Agreement
        1. Read README and command help before changing behavior.
        2. Add or update tests for each new feature.
        3. Keep changes isolated to the smallest possible file set.
        4. Document new commands and examples in README.
        5. Never remove original migration metrics unless explicitly requested.

        ## AI Backlog Ideas
        - Add `ai suggest` to propose migration tasks based on code patterns.
        - Add `ai prompt` to generate context-aware prompts for coding agents.
        - Add optional JSON output mode to integrate with external agent orchestration.
        - Add path ignore support (`.goswiftyignore`) for noisy directories.

        ## Detected AI Signals
        \(aiSignals.isEmpty ? "- No AI keywords detected yet." : aiSignals)

        ## Quality Gate
        - Build passes.
        - Tests pass.
        - New commands include `--help` examples in README.
        """
    }

    private static func detectWorkflowCommands(for path: String) -> [String] {
        let root = URL(fileURLWithPath: path)
        let fileManager = FileManager.default

        var commands: [String] = []

        if fileManager.fileExists(atPath: root.appendingPathComponent("Package.swift").path) {
            commands.append("swift build")
            commands.append("swift test")
            commands.append("swift run GoSwifty analyze <path>")
            commands.append("swift run GoSwifty ai audit <path>")
        }
        if fileManager.fileExists(atPath: root.appendingPathComponent("package.json").path) {
            commands.append("npm install")
            commands.append("npm test")
        }
        if fileManager.fileExists(atPath: root.appendingPathComponent("pyproject.toml").path) {
            commands.append("python -m pytest")
        }

        if commands.isEmpty {
            commands.append("Add build/test commands for this repository type.")
        }

        return commands
    }
}
