import ArgumentParser
import Foundation
import AppKit

struct Analyze: AsyncParsableCommand {
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

    @Argument(help: "Path to .trace file to analyze (optional, auto-discovers from .instruments/traces)")
    var tracePath: String?

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

    @Flag(
        name: .long,
        help: "Show only summary (ultra-compact, ~50 tokens)"
    )
    var summaryOnly: Bool = false

    @Flag(
        name: .long,
        help: "Suppress summary section from output"
    )
    var noSummary: Bool = false

    mutating func run() async throws {
        guard #available(macOS 14, *) else {
            throw TCATraceError.invalidTraceFile("smith-tca-trace requires macOS 14+")
        }

        // Use ProjectRootFinder to resolve trace location with fallback priority
        let traceURL = try ProjectRootFinder.findTrace(explicitPath: tracePath)

        if verbose {
            print("🚀 Analyzing trace")
            print("📁 Trace: \(traceURL.path)")
            if let size = try? FileManager.default.attributesOfItem(atPath: traceURL.path)[.size] as? Int64 {
                print("📊 Size: \(String(format: "%.1f", Double(size)/(1024*1024))) MB (bundle contents may be larger)")
            } else {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: traceURL.path, isDirectory: &isDir), isDir.boolValue, let dirSize = try? directorySize(traceURL) {
                    print("📊 Directory size: \(String(format: "%.1f", Double(dirSize)/(1024*1024))) MB")
                }
            }
            print("📄 Format: \(format.rawValue) | Mode: \(mode.rawValue)")
            print("🔎 Filters → feature:\(feature ?? "—") action:\(filter ?? "—") slowOnly:\(slowOnly) minDuration:\(minDuration)")
        }

        // Build parse filters
        let filters = ParseFilters(
            featureName: feature,
            actionName: filter,
            minDuration: minDuration,
            slowActionsOnly: slowOnly
        )

        // Parse trace and build analysis
        let parser = TraceParser(subsystemFilter: subsystem)
        let parsed = try await parser.parse(traceURL: traceURL, filters: filters)

        if verbose {
            print("✅ Parsed \(parsed.tcaSignposts.count) TCA signposts, \(parsed.actions.count) actions, \(parsed.effects.count) effects")
        }

        let metadata = AnalysisMetadata(
            name: name ?? traceURL.deletingPathExtension().lastPathComponent,
            tracePath: traceURL.path
        )

        let analysis = TraceAnalysis(
            metadata: metadata,
            actions: parsed.actions,
            effects: parsed.effects,
            sharedStateChanges: parsed.sharedStateChanges
        )

        if verbose {
            print("📈 Complexity: \(String(format: "%.1f", analysis.complexityScore))/100")
            print("⏱️  Duration: \(String(format: "%.2f", analysis.duration))s")
            print("🐌 Slow actions: \(analysis.metrics.slowActions)")
        }

        // Format output
        let outputString = OutputFormatter.format(analysis, mode: mode, format: format, summaryOnly: summaryOnly, noSummary: noSummary)

        // Write or print
        if let outputPath = output {
            try outputString.write(toFile: outputPath, atomically: true, encoding: String.Encoding.utf8)
            print("💾 Analysis written to \(outputPath)")
            if format == .html && open {
                NSWorkspace.shared.open(URL(fileURLWithPath: outputPath))
            }
        } else {
            print(outputString)
        }

        // Save for later comparison
        if save {
            let tagList = tags?
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty } ?? []

            let storage = try FileStorage()
            var analysisToStore = analysis
            analysisToStore.metadata.tags = tagList
            let savedURL = try await storage.save(analysisToStore, name: name, tags: tagList)
            print("✅ Saved analysis: \(savedURL.path)")
        }
    }

    /// Recursively compute directory size for .trace bundles
    private func directorySize(_ url: URL) throws -> Int64 {
        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .fileSizeKey]
        let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        )

        var total: Int64 = 0
        while let fileURL = enumerator?.nextObject() as? URL {
            let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
            if resourceValues.isRegularFile ?? false, let fileSize = resourceValues.fileSize {
                total += Int64(fileSize)
            }
        }
        return total
    }
}
