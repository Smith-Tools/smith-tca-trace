import ArgumentParser
import Foundation
import AppKit

struct Visualize: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate HTML visualizations for TCA analyses",
        discussion: """
        Creates interactive HTML visualizations from trace analyses or saved JSON files.

        Examples:
          smith-tca-trace visualize trace.trace --open
          smith-tca-trace visualize analysis.json --type timeline
          smith-tca-trace visualize baseline.trace current.trace --type comparison
        """
    )

    @Argument(help: "Input file path (.trace or saved .json)")
    var input: String

    @Option(
        name: .long,
        help: "Visualization type: interactive (default), comparison",
        completion: .list(["interactive", "comparison"])
    )
    var type: String = "interactive"

    @Option(
        name: .long,
        help: "Output HTML file path (optional)"
    )
    var output: String?

    @Flag(
        name: .long,
        help: "Open HTML in browser automatically"
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

        let inputURL = URL(fileURLWithPath: input)

        if verbose {
            print("🎨 Generating visualization for: \(input)")
            print("📊 Type: \(type)")
        }

        do {
            switch type.lowercased() {
            case "comparison":
                if inputURL.pathExtension == "json" {
                    throw TCATraceError.comparisonError("Comparison requires two input files")
                }
                // This would need to be extended to handle two-file comparison
                throw TCATraceError.comparisonError("Use 'smith-tca-trace compare' for comparisons with HTML output")

            default:
                // Generate interactive visualization
                let analysis = try await loadOrAnalyze(path: input, verbose: verbose)
                let html = HTMLFormatter.generateInteractiveHTML(analysis)

                let outputPath = output ?? "\(inputURL.deletingPathExtension().path).html"

                try html.write(toFile: outputPath, atomically: true, encoding: .utf8)
                print("✅ Interactive visualization created: \(outputPath)")

                if open {
                    NSWorkspace.shared.open(URL(fileURLWithPath: outputPath))
                }
            }

        } catch {
            print("❌ Error generating visualization: \(error.localizedDescription)")
            throw error
        }
    }

    private func loadOrAnalyze(path: String, verbose: Bool) async throws -> TraceAnalysis {
        let url = URL(fileURLWithPath: path)

        if url.pathExtension == "json" {
            // Load saved analysis
            if verbose {
                print("📂 Loading saved analysis")
            }

            let storage = try FileStorage()
            return try await storage.load(from: url)
        } else {
            // Parse trace file
            if verbose {
                print("🔍 Parsing trace file")
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
