import ArgumentParser
import Foundation

struct Stats: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show storage statistics for TCA analyses",
        discussion: """
        Displays statistics about stored analyses including count, size, and age.

        Example:
          smith-tca-trace stats --detailed
        """
    )

    @Flag(
        name: .long,
        help: "Show detailed statistics"
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
            let stats = try await storage.getStorageStats()

            print("📊 TCA Trace Storage Statistics")
            print("═" * 40)
            print("📁 Total Analyses: \(stats.totalAnalyses)")
            print("💾 Storage Size: \(stats.formattedSize)")

            if let oldest = stats.oldestAnalysis, let newest = stats.newestAnalysis {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short

                print("📅 Oldest Analysis: \(formatter.string(from: oldest))")
                print("📅 Newest Analysis: \(formatter.string(from: newest))")

                let daysBetween = Calendar.current.dateComponents([.day], from: oldest, to: newest).day ?? 0
                if daysBetween > 0 {
                    print("⏱️  Span: \(daysBetween) days")
                }
            }

            if detailed {
                print("\n🔍 Detailed Analysis:")

                let analyses = try await storage.listAnalyses(limit: 1000)

                if !analyses.isEmpty {
                    let complexities = analyses.map(\.complexityScore)
                    let avgComplexity = complexities.reduce(0, +) / Double(complexities.count)
                    let maxComplexity = complexities.max() ?? 0
                    let minComplexity = complexities.min() ?? 0

                    print("   📈 Average Complexity: \(String(format: "%.1f", avgComplexity))/100")
                    print("   📊 Complexity Range: \(String(format: "%.1f", minComplexity)) - \(String(format: "%.1f", maxComplexity))/100")

                    let totalActions = analyses.map(\.actionCount).reduce(0, +)
                    let totalSlowActions = analyses.map(\.slowActions).reduce(0, +)
                    let avgActions = Double(totalActions) / Double(analyses.count)

                    print("   🎯 Total Actions: \(totalActions)")
                    print("   🐌 Total Slow Actions: \(totalSlowActions)")
                    print("   📊 Average Actions per Trace: \(String(format: "%.1f", avgActions))")

                    // Top features
                    let allFeatures = Dictionary(grouping: analyses.flatMap { analysis in
                        analysis.name.components(separatedBy: ",")
                    }) { feature in
                        feature.trimmingCharacters(in: .whitespaces)
                    }

                    if !allFeatures.isEmpty {
                        let topFeatures = allFeatures.sorted { $0.value.count > $1.value.count }.prefix(5)
                        print("   🏗️  Most Common Feature Names:")
                        for (feature, count) in topFeatures {
                            print("      • \(feature): \(count) analyses")
                        }
                    }
                }

                // Size per analysis
                if stats.totalAnalyses > 0 {
                    let avgSizeKB = Double(stats.totalSizeBytes) / Double(stats.totalAnalyses) / 1024
                    print("   📏 Average Size per Analysis: \(String(format: "%.1f", avgSizeKB)) KB")
                }
            }

        } catch {
            print("❌ Error getting storage statistics: \(error.localizedDescription)")
            throw error
        }
    }
}

// String repetition operator for formatting
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}