import ArgumentParser
import Foundation

struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List saved TCA analyses (alias for history)",
        discussion: """
        Quick alias for 'smith-tca-trace history' - shows recent saved analyses.
        """
    )

    @Option(
        name: .long,
        help: "Show last N analyses (default: 10)"
    )
    var limit: Int = 10

    @Flag(
        name: .long,
        help: "Show detailed table format"
    )
    var detailed: Bool = false

    mutating func run() async throws {
        // Delegate to History command
        var history = History()
        history.limit = limit
        history.detailed = detailed
        try await history.run()
    }
}
