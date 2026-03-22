import ArgumentParser

struct GoSwifty: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A command-line tool to measure Swift migration and AI-agent readiness",
        subcommands: [Analyze.self, AI.self])

    init() { }
}

GoSwifty.main()
