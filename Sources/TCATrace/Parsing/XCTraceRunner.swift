import Foundation

/// Wrapper for Apple's xctrace command-line tool
@available(macOS 14, *)
struct XCTraceRunner: Sendable {
    enum ExportFormat: String {
        case xml
        case text
        case json
    }

    struct ExportResult {
        let signposts: Data
        let timeProfiler: Data?
        let syscalls: Data?
        let allocations: Data?
    }

    /// Export multiple tables from the trace: signposts (always), and optionally time profiler, syscalls, allocations.
    func exportTrace(
        at tracePath: URL,
        includeProfiler: Bool = true
    ) async throws -> ExportResult {
        func runExport(xpath: String) throws -> Data {
            let tempOutput = FileManager.default.temporaryDirectory
                .appendingPathComponent("xctrace_export_\(UUID().uuidString).xml")

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
            process.arguments = [
                "xctrace", "export",
                "--input", tracePath.path,
                "--output", tempOutput.path,
                "--xpath", xpath
            ]

            let pipe = Pipe()
            process.standardError = pipe

            try process.run()
            process.waitUntilExit()

            let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
            if !errorData.isEmpty {
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown xctrace error"
                print("xctrace stderr: \(errorMessage)")
            }

            guard process.terminationStatus == 0 else {
                throw TCATraceError.xctraceExportFailed(process.terminationStatus)
            }

            let data = try Data(contentsOf: tempOutput)
            try? FileManager.default.removeItem(at: tempOutput)
            return data
        }

        let signposts = try runExport(xpath: "/trace-toc/run[@number=\"1\"]/data/table[@schema=\"os-signpost\"]")

        var profiler: Data? = nil
        var syscalls: Data? = nil
        var allocs: Data? = nil

        if includeProfiler {
            // Correct schema names for Instruments 26.1
            profiler = try? runExport(xpath: "/trace-toc/run[@number=\"1\"]/data/table[@schema=\"time-sample\"]")
            syscalls = try? runExport(xpath: "/trace-toc/run[@number=\"1\"]/data/table[@schema=\"syscall\"]")
            // For allocations, use time-profile schema which contains heap allocation data
            allocs = try? runExport(xpath: "/trace-toc/run[@number=\"1\"]/data/table[@schema=\"time-profile\"]")
        }

        return ExportResult(signposts: signposts, timeProfiler: profiler, syscalls: syscalls, allocations: allocs)
    }

    /// Get trace information
    func getTraceInfo(at tracePath: URL) async throws -> TraceInfo {
        let tempOutput = FileManager.default.temporaryDirectory
            .appendingPathComponent("xctrace_info_\(UUID().uuidString).txt")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = [
            "xctrace", "export",
            "--input", tracePath.path,
            "--output", tempOutput.path,
            "--xpath", "/trace-toc"
        ]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw TCATraceError.xctraceExportFailed(process.terminationStatus)
        }

        let output = try String(contentsOf: tempOutput)
        try? FileManager.default.removeItem(at: tempOutput)

        // Parse basic trace info
        let lines = output.components(separatedBy: .newlines)
        let targetLine = lines.first { $0.contains("target-name") }
        let durationLine = lines.first { $0.contains("run-duration") }

        let targetName = targetLine?.components(separatedBy: "\"").dropFirst().first ?? "Unknown"
        let durationString = durationLine?.components(separatedBy: "\"").dropFirst().first
        let duration = Double(durationString ?? "0") ?? 0

        return TraceInfo(
            targetName: targetName,
            duration: duration,
            filePath: tracePath.path
        )
    }

    /// Check if xctrace is available
    func isAvailable() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["xctrace", "--version"]

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}

/// Basic information about a trace file
struct TraceInfo: Codable, Sendable {
    let targetName: String
    let duration: Double
    let filePath: String

    var formattedDuration: String {
        String(format: "%.1fs", duration)
    }
}
