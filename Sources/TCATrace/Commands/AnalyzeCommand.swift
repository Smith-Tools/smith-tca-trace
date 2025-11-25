import ArgumentParser
import Foundation
import AppKit

struct Analyze: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Analyze a TCA trace file",
        discussion: """
        Analyzes Instruments trace files to extract TCA performance metrics,
        complexity scores, and generate actionable recommendations.

        Examples:
          smith-tca-trace analyze trace.trace
          smith-tca-trace analyze trace.trace --mode user --save baseline
          smith-tca-trace analyze trace.trace --filter ReadingLibrary --slow-only
        """
    )

    @Argument(help: "Path to .trace file to analyze")
    var tracePath: String

    @Option(
        name: [.short, .long],
        help: "Output format: json, markdown, html",
        completion: .list(["json", "markdown", "html"])
    )
    var format: OutputFormat = .json

    @Option(
        name: [.short, .long],
        help: "Output mode: user (human-friendly), agent (complete data), compact (token-optimized, default)",
        completion: .list(["user", "agent", "compact"])
    )
    var mode: OutputMode = .compact

    @Option(
        name: .long,
        help: "Filter by feature name (e.g., ReadingLibrary)"
    )
    var feature: String?

    @Option(
        name: .long,
        help: "Filter by action name (partial match)"
    )
    var filter: String?

    @Option(
        name: .long,
        help: "App subsystem to filter (e.g., com.scroll.app, com.myapp.app). If not specified, detects from trace."
    )
    var subsystem: String?

    @Flag(
        name: .long,
        help: "Show only slow actions (>16ms)"
    )
    var slowOnly: Bool = false

    @Option(
        name: .long,
        help: "Minimum duration filter (seconds)"
    )
    var minDuration: Double = 0

    @Flag(
        name: [.short, .long],
        help: "Save analysis for later comparison"
    )
    var save: Bool = false

    @Option(
        name: .long,
        help: "Name for saved analysis (used with --save)"
    )
    var name: String?

    @Option(
        name: .long,
        help: "Tags for saved analysis (comma-separated, used with --save)"
    )
    var tags: String?

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

    func run() async throws {
        guard #available(macOS 14, *) else {
            throw TCATraceError.invalidTraceFile("smith-tca-trace requires macOS 14+")
        }

        let traceURL = URL(fileURLWithPath: tracePath)

        if verbose {
            print("🔍 Analyzing trace: \(tracePath)")
            print("📊 Output mode: \(mode.rawValue)")
            print("📄 Output format: \(format.rawValue)")
        }

        do {
            // Parse the trace
            let parser = TraceParser(subsystemFilter: subsystem)
            let parseFilters = ParseFilters(
                featureName: feature,
                actionName: filter,
                minDuration: minDuration,
                slowActionsOnly: slowOnly
            )

            if verbose {
                print("⏳ Parsing trace file...")
                if let sub = subsystem {
                    print("🎯 Filtering for subsystem: \(sub)")
                } else {
                    print("🎯 Auto-detecting app subsystem from trace...")
                }
            }

            let parsedData = try await parser.parse(traceURL: traceURL, filters: parseFilters)

            if verbose {
                print("✅ Parsed \(parsedData.actions.count) actions, \(parsedData.effects.count) effects, \(parsedData.sharedStateChanges.count) state changes")
            }

            // Create analysis
            let analysisName = name ?? traceURL.deletingPathExtension().lastPathComponent
            let metadata = AnalysisMetadata(
                name: analysisName,
                tracePath: tracePath,
                traceDate: parsedData.traceInfo.duration > 0 ? Date() : nil
            )

            let analysis = TraceAnalysis(
                metadata: metadata,
                actions: parsedData.actions,
                effects: parsedData.effects,
                sharedStateChanges: parsedData.sharedStateChanges
            )

            if verbose {
                print("📈 Analysis complete:")
                print("   • Complexity: \(String(format: "%.1f", analysis.complexityScore))/100")
                print("   • Slow actions: \(analysis.metrics.slowActions)/\(analysis.actions.count)")
                print("   • Avg duration: \(String(format: "%.1f", analysis.metrics.avgDuration * 1000))ms")
            }

            // Generate output
            let outputString = OutputFormatter.format(analysis, mode: mode, format: format)

            if verbose {
                print("📝 Output generated (\(outputString.count) characters)")
            }

            // Write output
            if let outputPath = output {
                try outputString.write(toFile: outputPath, atomically: true, encoding: .utf8)
                print("✅ Output written to: \(outputPath)")

                // Open HTML in browser if requested
                if format == .html && open {
                    NSWorkspace.shared.open(URL(fileURLWithPath: outputPath))
                }
            } else {
                print(outputString)
            }

            // Save analysis if requested
            if save {
                let storage = try FileStorage()
                let tagsArray = tags?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? []

                if verbose {
                    print("💾 Saving analysis...")
                }

                let savedURL = try await storage.save(analysis, name: analysisName, tags: tagsArray)
                print("✅ Analysis saved to: \(savedURL.path)")
            }

        } catch {
            print("❌ Error analyzing trace: \(error.localizedDescription)")
            throw error
        }
    }
}