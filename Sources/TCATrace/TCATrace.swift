import ArgumentParser
import Foundation

@main
struct TCATrace: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "TCA performance profiling and analysis tool",
        discussion: """
        smith-tca-trace analyzes The Composable Architecture (TCA) applications using Instruments traces
        to identify performance bottlenecks, complexity issues, and provide actionable recommendations.

        By default, outputs compact JSON optimized for AI agents (30-40% token reduction).
        Use --mode user for human-friendly output or --mode agent for complete data.
        """,
        version: "1.0.0",
        subcommands: [
            Analyze.self,
            Compare.self,
            History.self,
            Visualize.self,
            List.self,
            Delete.self,
            Stats.self
        ],
        defaultSubcommand: Analyze.self
    )
}