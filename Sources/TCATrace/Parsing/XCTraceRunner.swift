import Foundation

/// Wrapper for Apple's xctrace command-line tool
@available(macOS 14, *)
struct XCTraceRunner: Sendable {
    enum ExportFormat: String {
        case xml
        case text
        case json
    }

    /// Export trace data using xctrace
    func exportTrace(
        at tracePath: URL,
        format: ExportFormat = .xml,
        xpath: String? = nil
    ) async throws -> Data {
        let tempOutput = FileManager.default.temporaryDirectory
            .appendingPathComponent("xctrace_export_\(UUID().uuidString).\(format.rawValue)")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")

        var arguments = [
            "xctrace", "export",
            "--input", tracePath.path,
            "--output", tempOutput.path
        ]

        // Use XPath to filter for signpost data
        if let xpath = xpath {
            arguments.append("--xpath")
            arguments.append(xpath)
        } else {
            // Default XPath for signposts
            arguments.append("--xpath")
            arguments.append("/trace-toc/run/data/table[@schema='os-signpost']")
        }

        process.arguments = arguments

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

        // Clean up temp file
        try? FileManager.default.removeItem(at: tempOutput)

        return data
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