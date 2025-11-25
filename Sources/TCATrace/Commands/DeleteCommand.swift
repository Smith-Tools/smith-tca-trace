import ArgumentParser
import Foundation

struct Delete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Delete saved TCA analyses",
        discussion: """
        Removes saved analyses from storage. Use with caution - this cannot be undone.

        Examples:
          smith-tca-trace delete analysis_2024-01-15T10:30:00Z.json
          smith-tca-trace delete --cleanup 30        # Delete analyses older than 30 days
        """
    )

    @Argument(help: "Filename of analysis to delete")
    var filename: String?

    @Flag(
        name: .long,
        help: "Delete analyses older than specified days"
    )
    var cleanup: Bool = false

    @Option(
        name: .long,
        help: "Age threshold for cleanup (days, default: 30)"
    )
    var days: Int = 30

    @Flag(
        name: .long,
        help: "Dry run - show what would be deleted without actually deleting"
    )
    var dryRun: Bool = false

    @Flag(
        name: [.short, .long],
        help: "Verbose output"
    )
    var verbose: Bool = false

    mutating func run() async throws {
        guard #available(macOS 14, *) else {
            throw TCATraceError.storageError("smith-tca-trace requires macOS 14+")
        }

        let storage = try FileStorage()

        if cleanup {
            // Cleanup old analyses
            if verbose {
                print("🧹 Cleaning up analyses older than \(days) days...")
            }

            let deletedCount = try await storage.cleanupOldAnalyses(olderThan: days)

            if dryRun {
                print("🔍 Dry run: Would delete \(deletedCount) old analyses")
            } else {
                print("✅ Deleted \(deletedCount) old analyses")
            }

        } else if let filename = filename {
            // Delete specific file
            if verbose {
                print("🗑️  Deleting analysis: \(filename)")
            }

            if dryRun {
                print("🔍 Dry run: Would delete \(filename)")
            } else {
                try storage.delete(filename: filename)
                print("✅ Deleted analysis: \(filename)")
            }

        } else {
            print("❌ Please specify either a filename to delete or use --cleanup")
            print("💡 Use 'tca-trace history' to see available analyses")
            throw TCATraceError.storageError("No target specified for deletion")
        }
    }
}
