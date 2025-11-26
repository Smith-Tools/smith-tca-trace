import Foundation

/// Utility for discovering project root and canonical trace locations
struct ProjectRootFinder {
    /// Finds the project root by walking up directory tree
    /// - Parameter startingFrom: Directory to start search from (defaults to current directory)
    /// - Returns: URL of project root, or nil if not found
    static func findProjectRoot(
        startingFrom: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    ) -> URL? {
        var current = startingFrom

        let markers = ["Package.swift", ".xcodeproj", ".git"]

        while current.path != "/" {
            for marker in markers {
                let markerPath = current.appendingPathComponent(marker)
                if FileManager.default.fileExists(atPath: markerPath.path) {
                    return current
                }
            }
            current = current.deletingLastPathComponent()
        }

        return nil
    }

    /// Gets the canonical traces directory for a project
    /// - Parameter projectRoot: Root URL of the project
    /// - Returns: URL to `.instruments/traces` directory
    static func getTracesDirectory(projectRoot: URL) -> URL {
        projectRoot.appendingPathComponent(".instruments").appendingPathComponent("traces")
    }

    /// Lists available trace files in canonical location
    /// - Parameter projectRoot: Root URL of the project
    /// - Returns: Array of trace file URLs, sorted by modification date (newest first)
    /// - Throws: FileNotFound if traces directory doesn't exist
    static func listTraces(projectRoot: URL) throws -> [URL] {
        let tracesDir = getTracesDirectory(projectRoot: projectRoot)

        guard FileManager.default.fileExists(atPath: tracesDir.path) else {
            throw TCATraceError.noTracesFound(
                message: "No .instruments/traces directory found at: \(tracesDir.path)\n\n" +
                "To record a trace:\n" +
                "1. Open Instruments\n" +
                "2. Profile your TCA app\n" +
                "3. Save trace to: \(tracesDir.path)/\n" +
                "4. Then run: smith-tca-trace analyze"
            )
        }

        let traces = try FileManager.default.contentsOfDirectory(
            at: tracesDir,
            includingPropertiesForKeys: [.contentModificationDateKey]
        )
        .filter { $0.pathExtension == "trace" }
        .sorted { a, b in
            let aDate = try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
            let bDate = try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
            return (aDate ?? Date.distantPast) > (bDate ?? Date.distantPast)  // Newest first
        }

        return traces
    }

    /// Intelligently selects a trace file from canonical location using fallback priority
    /// Priority order:
    /// 1. current.trace (explicit current marker)
    /// 2. baseline.trace (reference baseline)
    /// 3. Most recent by modification time
    /// 4. Only trace if just one exists
    ///
    /// - Parameter projectRoot: Root URL of the project
    /// - Returns: URL of selected trace file
    /// - Throws: Helpful error if no traces found or multiple traces without clear choice
    static func selectTrace(projectRoot: URL) throws -> URL {
        let traces = try listTraces(projectRoot: projectRoot)

        if traces.isEmpty {
            let tracesDir = getTracesDirectory(projectRoot: projectRoot)
            throw TCATraceError.noTracesFound(
                message: "No .trace files found in \(tracesDir.path)\n\n" +
                "To record a trace:\n" +
                "1. Open Instruments\n" +
                "2. Profile your TCA app\n" +
                "3. Save trace to: \(tracesDir.path)/\n" +
                "4. Or use CLI:\n" +
                "   instruments -t 'System Trace' \\\n" +
                "     -o \(tracesDir.path)/trace.trace \\\n" +
                "     -D YourApp\n" +
                "5. Then run: smith-tca-trace analyze"
            )
        }

        // Fallback Priority 1: Explicit "current.trace"
        if let current = traces.first(where: { $0.lastPathComponent == "current.trace" }) {
            return current
        }

        // Fallback Priority 2: Explicit "baseline.trace"
        if let baseline = traces.first(where: { $0.lastPathComponent == "baseline.trace" }) {
            return baseline
        }

        // Fallback Priority 3: Most recent by modification time (already sorted)
        if let mostRecent = traces.first {
            return mostRecent
        }

        // Fallback Priority 4: Only one trace (shouldn't reach here due to earlier isEmpty check)
        throw TCATraceError.noTracesFound(message: "Unable to select appropriate trace file")
    }

    /// Finds a trace file using the complete fallback strategy
    /// 1. Uses provided path if given
    /// 2. Discovers project root
    /// 3. Uses canonical location with intelligent selection
    ///
    /// - Parameter explicitPath: Explicit trace path (if provided by user)
    /// - Returns: URL of trace file to analyze
    /// - Throws: Helpful error messages at each step
    static func findTrace(explicitPath: String?) throws -> URL {
        // Fallback 1: Use explicit path if provided
        if let providedPath = explicitPath {
            let url = URL(fileURLWithPath: providedPath)
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else {
                throw TCATraceError.fileNotFound(url.path)
            }
            return url
        }

        // Fallback 2: Find project root
        guard let projectRoot = findProjectRoot() else {
            throw TCATraceError.noProjectFound(
                message: "Cannot find project root (Package.swift, .xcodeproj, or .git)\n\n" +
                "Either:\n" +
                "1. Run from inside a Swift project, or\n" +
                "2. Provide explicit path: smith-tca-trace analyze /path/to/trace.trace"
            )
        }

        // Fallback 3 & 4: Use canonical location with intelligent selection
        return try selectTrace(projectRoot: projectRoot)
    }
}
