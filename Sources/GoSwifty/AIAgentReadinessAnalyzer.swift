//
//  AIAgentReadinessAnalyzer.swift
//
//
//  Created by Codex on 3/22/26.
//

import Foundation

final class AIAgentReadinessAnalyzer {
    private let paths: [String]

    init(paths: [String]) {
        self.paths = paths
    }

    func analyze() -> AIAgentReadinessReport {
        var totalFiles = 0
        var extensionHistogram: [String: Int] = [:]
        var aiKeywordHits: [String: Int] = [:]

        var hasReadme = false
        var hasContributing = false
        var hasDocsDirectory = false
        var hasLicense = false
        var hasTests = false
        var hasCiPipeline = false
        var hasDependencyManifest = false
        var hasEnvExample = false
        var hasScripts = false
        var hasIssueTemplates = false

        let targetPaths = paths.isEmpty ? ["."] : paths

        for path in targetPaths {
            guard let enumerator = FileManager.default.enumerator(atPath: path) else {
                continue
            }

            for case let relativePath as String in enumerator {
                let fullPath = (path as NSString).appendingPathComponent(relativePath)
                var isDirectory: ObjCBool = false
                guard FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory), !isDirectory.boolValue else {
                    continue
                }

                totalFiles += 1
                let normalizedPath = relativePath
                    .replacingOccurrences(of: "\\", with: "/")
                    .lowercased()
                let fileName = URL(fileURLWithPath: relativePath).lastPathComponent.lowercased()

                let ext = (fileName as NSString).pathExtension.lowercased()
                let extKey = ext.isEmpty ? "(no_ext)" : ext
                extensionHistogram[extKey, default: 0] += 1

                if fileName == "readme.md" || fileName == "readme" {
                    hasReadme = true
                }
                if fileName == "contributing.md" || fileName == "contributing" {
                    hasContributing = true
                }
                if fileName == "license" || fileName == "license.md" {
                    hasLicense = true
                }
                if normalizedPath.hasPrefix("docs/") || normalizedPath.contains("/docs/") {
                    hasDocsDirectory = true
                }
                if normalizedPath.hasPrefix("tests/") || normalizedPath.contains("/tests/") || normalizedPath.contains("/test/") || fileName.contains("test") {
                    hasTests = true
                }
                if normalizedPath.hasPrefix(".github/workflows/")
                    || fileName == ".gitlab-ci.yml"
                    || fileName == "azure-pipelines.yml"
                    || fileName == "circle.yml"
                    || normalizedPath.contains(".circleci/config.yml") {
                    hasCiPipeline = true
                }
                if ["package.swift", "package.json", "pyproject.toml", "requirements.txt", "go.mod", "cargo.toml", "pom.xml", "build.gradle", "gemfile"].contains(fileName) {
                    hasDependencyManifest = true
                }
                if [".env.example", "env.example", ".env.sample", ".env.template"].contains(fileName) {
                    hasEnvExample = true
                }
                if normalizedPath.hasPrefix("scripts/")
                    || normalizedPath.contains("/scripts/")
                    || fileName == "makefile"
                    || fileName == "justfile" {
                    hasScripts = true
                }
                if normalizedPath.hasPrefix(".github/issue_template/")
                    || normalizedPath.hasPrefix(".github/pull_request_template")
                    || normalizedPath.contains("/.github/issue_template/")
                    || normalizedPath.contains("/.github/pull_request_template") {
                    hasIssueTemplates = true
                }

                guard shouldInspectAsText(path: fullPath, fileExtension: ext) else {
                    continue
                }

                guard let content = try? String(contentsOfFile: fullPath, encoding: .utf8) else {
                    continue
                }

                let loweredContent = content.lowercased()
                for keyword in aiKeywords {
                    if loweredContent.contains(keyword) {
                        aiKeywordHits[keyword, default: 0] += 1
                    }
                }
            }
        }

        let score = calculateScore(
            hasReadme: hasReadme,
            hasContributing: hasContributing,
            hasDocsDirectory: hasDocsDirectory,
            hasLicense: hasLicense,
            hasTests: hasTests,
            hasCiPipeline: hasCiPipeline,
            hasDependencyManifest: hasDependencyManifest,
            hasEnvExample: hasEnvExample,
            hasScripts: hasScripts,
            hasIssueTemplates: hasIssueTemplates,
            aiKeywordHits: aiKeywordHits
        )

        let recommendations = buildRecommendations(
            hasReadme: hasReadme,
            hasContributing: hasContributing,
            hasDocsDirectory: hasDocsDirectory,
            hasTests: hasTests,
            hasCiPipeline: hasCiPipeline,
            hasEnvExample: hasEnvExample,
            hasScripts: hasScripts,
            hasIssueTemplates: hasIssueTemplates,
            aiKeywordHits: aiKeywordHits
        )

        return AIAgentReadinessReport(
            totalFiles: totalFiles,
            extensionHistogram: extensionHistogram,
            hasReadme: hasReadme,
            hasContributing: hasContributing,
            hasDocsDirectory: hasDocsDirectory,
            hasLicense: hasLicense,
            hasTests: hasTests,
            hasCiPipeline: hasCiPipeline,
            hasDependencyManifest: hasDependencyManifest,
            hasEnvExample: hasEnvExample,
            hasScripts: hasScripts,
            hasIssueTemplates: hasIssueTemplates,
            aiKeywordHits: aiKeywordHits,
            score: score,
            recommendations: recommendations
        )
    }

    private var aiKeywords: [String] {
        [
            "openai", "anthropic", "langchain", "llamaindex", "autogen", "crewai",
            "agent", "prompt", "tool calling", "function calling", "rag",
            "embedding", "vector database", "retrieval", "mcp", "model context protocol"
        ]
    }

    private func shouldInspectAsText(path: String, fileExtension: String) -> Bool {
        let textExtensions = Set([
            "swift", "m", "mm", "h", "py", "js", "ts", "tsx", "jsx", "json", "md",
            "txt", "yml", "yaml", "toml", "rb", "go", "java", "kt", "kts", "rs",
            "cs", "c", "cpp", "cc", "html", "xml", "sh"
        ])

        guard textExtensions.contains(fileExtension) else {
            return false
        }

        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path),
              let bytes = attributes[.size] as? NSNumber else {
            return true
        }

        return bytes.intValue <= 1_048_576
    }

    private func calculateScore(
        hasReadme: Bool,
        hasContributing: Bool,
        hasDocsDirectory: Bool,
        hasLicense: Bool,
        hasTests: Bool,
        hasCiPipeline: Bool,
        hasDependencyManifest: Bool,
        hasEnvExample: Bool,
        hasScripts: Bool,
        hasIssueTemplates: Bool,
        aiKeywordHits: [String: Int]
    ) -> Int {
        var score = 0

        if hasReadme { score += 10 }
        if hasContributing { score += 5 }
        if hasDocsDirectory { score += 5 }
        if hasLicense { score += 5 }

        if hasTests { score += 10 }
        if hasCiPipeline { score += 8 }
        if hasDependencyManifest { score += 7 }

        if hasEnvExample { score += 6 }
        if hasScripts { score += 7 }
        if hasIssueTemplates { score += 7 }

        let aiSignalCount = aiKeywordHits.count
        score += min(30, aiSignalCount * 3)

        return min(100, score)
    }

    private func buildRecommendations(
        hasReadme: Bool,
        hasContributing: Bool,
        hasDocsDirectory: Bool,
        hasTests: Bool,
        hasCiPipeline: Bool,
        hasEnvExample: Bool,
        hasScripts: Bool,
        hasIssueTemplates: Bool,
        aiKeywordHits: [String: Int]
    ) -> [String] {
        var result: [String] = []

        if !hasReadme {
            result.append("Add a README with architecture, setup, and command usage for both humans and agents.")
        }
        if !hasContributing {
            result.append("Add CONTRIBUTING.md to define coding standards and pull request expectations.")
        }
        if !hasDocsDirectory {
            result.append("Create a docs/ folder for design decisions and AI integration notes.")
        }
        if !hasTests {
            result.append("Increase test coverage so agent-generated changes can be validated automatically.")
        }
        if !hasCiPipeline {
            result.append("Set up CI to run build and tests on each pull request.")
        }
        if !hasEnvExample {
            result.append("Add .env.example documenting required API keys for AI providers.")
        }
        if !hasScripts {
            result.append("Provide scripts or task runners for common workflows (build/test/lint/audit).")
        }
        if !hasIssueTemplates {
            result.append("Add issue and PR templates to structure requests for agents and contributors.")
        }
        if aiKeywordHits.isEmpty {
            result.append("Add a first AI capability (for example an agent command, prompt runner, or RAG helper).")
        } else {
            result.append("Convert detected AI signals into a documented CLI/API workflow so agents can run it reliably.")
        }

        return result
    }
}
