import ArgumentParser
import Foundation
import AppKit

struct Compare: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Compare two TCA traces to detect regressions and improvements",
        discussion: """
        Compares two trace analyses to identify performance regressions,
        improvements, and complexity changes between them.

        Examples:
          smith-tca-trace compare baseline.trace current.trace
          smith-tca-trace compare baseline.json current.json --threshold 30
          smith-tca-trace compare baseline.trace current.trace --save comparison_report
        """
    )

    @Argument(help: "Baseline trace file (can be .trace or saved .json)")
    var baseline: String

    @Argument(help: "Current trace file (can be .trace or saved .json)")
    var current: String

    @Option(
        name: .long,
        help: "Regression threshold percentage (default: 20%)"
    )
    var threshold: Double = 20.0

    @Option(
        name: [.short, .long],
        help: "Output format: json, markdown, html",
        completion: .list(["json", "markdown", "html"])
    )
    var format: OutputFormat = .markdown

    @Option(
        name: [.short, .long],
        help: "Output mode: user, agent, compact",
        completion: .list(["user", "agent", "compact"])
    )
    var mode: OutputMode = .user

    @Option(
        name: .long,
        help: "Output file path (optional, defaults to stdout)"
    )
    var output: String?

    @Flag(
        name: .long,
        help: "Open HTML output in browser automatically"
    )
    var open: Bool = false

    @Flag(
        name: [.short, .long],
        help: "Verbose output"
    )
    var verbose: Bool = false

    mutating func run() async throws {
        guard #available(macOS 14, *) else {
            throw TCATraceError.invalidTraceFile("smith-tca-trace requires macOS 14+")
        }

        if verbose {
            print("🔍 Comparing traces:")
            print("   • Baseline: \(baseline)")
            print("   • Current: \(current)")
            print("   • Threshold: \(threshold)%")
        }

        do {
            // Load or parse baseline
            let baselineAnalysis = try await loadOrAnalyze(path: baseline, verbose: verbose)
            let currentAnalysis = try await loadOrAnalyze(path: current, verbose: verbose)

            // Compare analyses
            let comparator = TraceComparator()
            let comparison = comparator.compare(
                baseline: baselineAnalysis,
                current: currentAnalysis,
                threshold: threshold
            )

            if verbose {
                print("📊 Comparison complete:")
                print("   • Regressions: \(comparison.regressions.count)")
                print("   • Improvements: \(comparison.improvements.count)")
                print("   • Complexity change: \(String(format: "%+.1f", comparison.complexityChange))")
            }

            // Generate output
            let outputString = OutputFormatter.format(comparison, mode: mode, format: format)

            if verbose {
                print("📝 Output generated")
            }

            // Write output
            if let outputPath = output {
                try outputString.write(toFile: outputPath, atomically: true, encoding: .utf8)
                print("✅ Comparison report written to: \(outputPath)")

                // Open HTML in browser if requested
                if format == .html && open {
                    NSWorkspace.shared.open(URL(fileURLWithPath: outputPath))
                }
            } else {
                print(outputString)
            }

            // Print summary if verbose
            if verbose && !comparison.regressions.isEmpty {
                print("\n🔴 Top Regressions:")
                for regression in comparison.regressions.prefix(3) {
                    print("   • \(regression.actionName): +\(String(format: "%.0f", regression.percentChange))%")
                }
            }

            if verbose && !comparison.improvements.isEmpty {
                print("\n✅ Top Improvements:")
                for improvement in comparison.improvements.prefix(3) {
                    print("   • \(improvement.actionName): -\(String(format: "%.0f", improvement.percentChange))%")
                }
            }

        } catch {
            print("❌ Error comparing traces: \(error.localizedDescription)")
            throw error
        }
    }

    private func loadOrAnalyze(path: String, verbose: Bool) async throws -> TraceAnalysis {
        let url = URL(fileURLWithPath: path)

        if url.pathExtension == "json" {
            // Load saved analysis
            if verbose {
                print("📂 Loading saved analysis: \(path)")
            }

            let storage = try FileStorage()
            return try await storage.load(from: url)
        } else {
            // Parse trace file
            if verbose {
                print("🔍 Parsing trace file: \(path)")
            }

            let parser = TraceParser()
            let parsedData = try await parser.parse(traceURL: url)

            let metadata = AnalysisMetadata(
                name: url.deletingPathExtension().lastPathComponent,
                tracePath: path
            )

            return TraceAnalysis(
                metadata: metadata,
                actions: parsedData.actions,
                effects: parsedData.effects,
                sharedStateChanges: parsedData.sharedStateChanges
            )
        }
    }
}
