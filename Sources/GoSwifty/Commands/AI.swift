//
//  AI.swift
//
//
//  Created by Codex on 3/22/26.
//

import ArgumentParser
import Foundation
import Rainbow

struct AI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ai",
        abstract: "Utilities that help adapt your repository for AI and AI agents",
        subcommands: [AIAudit.self, AIScaffold.self]
    )
}

struct AIAudit: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Audit repository readiness for AI and agent workflows")

    @Argument(help: "List of folders to analyze. Defaults to current directory when omitted.")
    private var paths: [String] = []

    @Option(name: .shortAndLong, help: "Save the report to a markdown file.")
    var output: String?

    func run() throws {
        let analyzedPaths = paths.isEmpty ? ["."] : paths
        let report = AIAgentReadinessAnalyzer(paths: analyzedPaths).analyze()
        let renderedReport = report.asText(analyzedPaths: analyzedPaths)

        print(renderedReport)

        if let output = output {
            try renderedReport.write(toFile: output, atomically: true, encoding: .utf8)
            print("")
            print("Saved AI readiness report to \(output)".green.bold)
        }
    }
}

struct AIScaffold: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Generate an AGENTS.md starter guide for coding agents")

    @Argument(help: "Folder to inspect before generating AGENTS.md")
    private var path: String

    @Option(name: .shortAndLong, help: "Output path for generated guide file.")
    var output: String = "AGENTS.md"

    func run() throws {
        let report = AIAgentReadinessAnalyzer(paths: [path]).analyze()
        let markdown = AgentGuideWriter.makeMarkdown(report: report, analyzedPath: path)
        try markdown.write(toFile: output, atomically: true, encoding: .utf8)

        print("Generated \(output) for \(path)".green.bold)
    }
}
