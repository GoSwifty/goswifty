//
//  AIAgentReadinessReport.swift
//
//
//  Created by Codex on 3/22/26.
//

import Foundation

struct AIAgentReadinessReport {
    let totalFiles: Int
    let extensionHistogram: [String: Int]

    let hasReadme: Bool
    let hasContributing: Bool
    let hasDocsDirectory: Bool
    let hasLicense: Bool

    let hasTests: Bool
    let hasCiPipeline: Bool
    let hasDependencyManifest: Bool

    let hasEnvExample: Bool
    let hasScripts: Bool
    let hasIssueTemplates: Bool

    let aiKeywordHits: [String: Int]

    let score: Int
    let recommendations: [String]

    var level: String {
        switch score {
        case 80...100: return "High"
        case 50...79: return "Medium"
        default: return "Low"
        }
    }

    func asText(analyzedPaths: [String]) -> String {
        let topExtensions = extensionHistogram
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }
                return lhs.value > rhs.value
            }
            .prefix(8)
            .map { key, value in "- \(key): \(value)" }
            .joined(separator: "\n")

        let topKeywords = aiKeywordHits
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }
                return lhs.value > rhs.value
            }
            .prefix(8)
            .map { key, value in "- \(key): \(value)" }
            .joined(separator: "\n")

        let recommendationsText: String
        if recommendations.isEmpty {
            recommendationsText = "- Great baseline. Continue with incremental AI feature delivery."
        } else {
            recommendationsText = recommendations.map { "- \($0)" }.joined(separator: "\n")
        }

        return """
        # GoSwifty AI Readiness Report

        ## Targets
        \(analyzedPaths.map { "- \($0)" }.joined(separator: "\n"))

        ## Summary
        - Files scanned: \(totalFiles)
        - Readiness score: \(score)/100
        - Readiness level: \(level)

        ## Engineering Signals
        - README: \(hasReadme ? "yes" : "no")
        - CONTRIBUTING: \(hasContributing ? "yes" : "no")
        - docs/ directory: \(hasDocsDirectory ? "yes" : "no")
        - LICENSE: \(hasLicense ? "yes" : "no")
        - Tests: \(hasTests ? "yes" : "no")
        - CI pipeline: \(hasCiPipeline ? "yes" : "no")
        - Dependency manifest: \(hasDependencyManifest ? "yes" : "no")
        - Env example: \(hasEnvExample ? "yes" : "no")
        - Scripts/Task runner: \(hasScripts ? "yes" : "no")
        - Issue/PR templates: \(hasIssueTemplates ? "yes" : "no")

        ## Top File Extensions
        \(topExtensions.isEmpty ? "- None found" : topExtensions)

        ## AI Keyword Signals
        \(topKeywords.isEmpty ? "- No AI keywords were detected in text files." : topKeywords)

        ## Recommended Next Steps
        \(recommendationsText)
        """
    }
}
