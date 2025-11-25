import ArgumentParser
import Foundation

struct History: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List and search saved TCA analyses",
        discussion: """
        Lists previously saved analyses with optional filtering and searching capabilities.

        Examples:
          smith-tca-trace history                           # Show recent analyses
          smith-tca-trace history --limit 20                # Show last 20 analyses
          smith-tca-trace history --tag baseline           # Show analyses with 'baseline' tag
          smith-tca-trace history --name ReadingLibrary     # Search for specific analyses
          smith-tca-trace history --sort complexity         # Sort by complexity score
        """
    )

    @Option(
        name: .long,
        help: "Show last N analyses (default: 10)"
    )
    var limit: Int = 10

    @Option(
        name: .long,
        help: "Filter by tag"
    )
    var tag: String?

    @Option(
        name: .long,
        help: "Search by name (partial match)"
    )
    var name: String?

    @Option(
        name: .long,
        help: "Sort by: date (default), name, complexity",
        completion: .list(["date", "name", "complexity"])
    )
    var sort: String = "date"

    @Option(
        name: [.short, .long],
        help: "Output format: table, json",
        completion: .list(["table", "json"])
    )
    var format: String = "table"

    @Flag(
        name: .long,
        help: "Show detailed information"
    )
    var detailed: Bool = false

    @Flag(
        name: [.short, .long],
        help: "Verbose output"
    )
    var verbose: Bool = false

    func run() async throws {
        guard #available(macOS 14, *) else {
            throw TCATraceError.storageError("smith-tca-trace requires macOS 14+")
        }

        do {
            let storage = try FileStorage()

            if verbose {
                print("🔍 Loading analysis history...")
            }

            // Determine sort method
            let sortBy: FileStorage.SortBy
            switch sort.lowercased() {
            case "name": sortBy = .name
            case "complexity": sortBy = .complexity
            default: sortBy = .date
            }

            // Get analyses
            let analyses: [AnalysisSummary]
            if let namePattern = name {
                analyses = try await storage.findAnalyses(namePattern: namePattern)
            } else {
                analyses = try await storage.listAnalyses(
                    matchingTag: tag,
                    limit: limit,
                    sortBy: sortBy
                )
            }

            if analyses.isEmpty {
                print("📭 No saved analyses found")
                if let tag = tag {
                    print("   with tag '\(tag)'")
                }
                if let name = name {
                    print("   matching '\(name)'")
                }
                return
            }

            if verbose {
                print("📊 Found \(analyses.count) analyses")
            }

            // Format output
            switch format.lowercased() {
            case "json":
                print(formatAsJSON(analyses))
            default:
                print(formatAsTable(analyses, detailed: detailed))
            }

        } catch {
            print("❌ Error loading history: \(error.localizedDescription)")
            throw error
        }
    }

    private func formatAsTable(_ analyses: [AnalysisSummary], detailed: Bool) -> String {
        var table = ""

        if detailed {
            table += """
            ┌─────────────────────────────────────────────────────────────────────────────────┐
            │                              TCA Analysis History                              │
            ├─────────────────────┬─────────────────┬─────────┬───────────┬─────────┬─────────┤
            │ Name                │ Date             │ Score   │ Actions   │ Slow    │ Avg     │
            │                     │                 │ /100    │           │         │ (ms)    │
            ├─────────────────────┼─────────────────┼─────────┼───────────┼─────────┼─────────┤
            """

            for analysis in analyses {
                let name = String(analysis.name.prefix(19)).padding(toLength: 19, withPad: " ", startingAt: 0)
                let date = analysis.formattedDate.padding(toLength: 15, withPad: " ", startingAt: 0)
                let score = String(format: "%3.0f", analysis.complexityScore).padding(toLength: 7, withPad: " ", startingAt: 0)
                let actions = String(analysis.actionCount).padding(toLength: 7, withPad: " ", startingAt: 0)
                let slow = String(analysis.slowActions).padding(toLength: 7, withPad: " ", startingAt: 0)
                let avg = String(format: "%7.1f", analysis.avgDurationMS)

                table += "\n│ \(name) │ \(date) │ \(score) │ \(actions) │ \(slow) │ \(avg) │"
            }

            table += """

            └─────────────────────┴─────────────────┴─────────┴───────────┴─────────┴─────────┘

            """
        } else {
            table += "📊 Recent TCA Analyses:\n\n"

            for (index, analysis) in analyses.enumerated() {
                let date = analysis.formattedDate
                let complexity = analysis.complexityRating
                let duration = String(format: "%.1f", analysis.avgDurationMS)

                table += """
                \(index + 1). \(analysis.name)
                   📅 \(date) • 📊 \(complexity) • 🎯 \(analysis.actionCount) actions (\(analysis.slowActions) slow) • ⚡ \(duration)ms avg
                """

                if !analysis.tags.isEmpty {
                    table += " • 🏷️  \(analysis.tags.joined(separator: ", "))"
                }

                table += "\n\n"
            }
        }

        return table
    }

    private func formatAsJSON(_ analyses: [AnalysisSummary]) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try! encoder.encode(analyses)
        return String(data: data, encoding: .utf8)!
    }
}