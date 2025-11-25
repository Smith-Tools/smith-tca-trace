import Foundation

/// File-based storage for TCA trace analyses
@available(macOS 14, *)
struct FileStorage: Sendable {
    private let storageDirectory: URL

    init() throws {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        storageDirectory = homeDir.appendingPathComponent(".tca-trace/analyses")
        try FileManager.default.createDirectory(
            at: storageDirectory,
            withIntermediateDirectories: true
        )
    }

    /// Save analysis with automatic naming
    func save(
        _ analysis: TraceAnalysis,
        name: String? = nil,
        tags: [String] = []
    ) async throws -> URL {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename: String

        if let name = name {
            // Sanitize filename
            let sanitizedName = name.replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "_", options: .regularExpression)
            filename = "\(sanitizedName)_\(timestamp).json"
        } else {
            filename = "trace_\(timestamp).json"
        }

        let fileURL = storageDirectory.appendingPathComponent(filename)

        // Add metadata
        var enrichedAnalysis = analysis
        enrichedAnalysis.metadata.storedAt = Date()
        enrichedAnalysis.metadata.tags = tags

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(enrichedAnalysis)
        try data.write(to: fileURL)

        return fileURL
    }

    /// Load saved analysis
    func load(from url: URL) async throws -> TraceAnalysis {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TraceAnalysis.self, from: data)
    }

    /// Load analysis by filename
    func load(filename: String) async throws -> TraceAnalysis {
        let fileURL = storageDirectory.appendingPathComponent(filename)
        return try await load(from: fileURL)
    }

    /// List all saved analyses
    func listAnalyses(
        matchingTag tag: String? = nil,
        limit: Int? = nil,
        sortBy: SortBy = .date
    ) async throws -> [AnalysisSummary] {
        let contents = try FileManager.default.contentsOfDirectory(
            at: storageDirectory,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey]
        )

        var analyses: [AnalysisSummary] = []

        for fileURL in contents where fileURL.pathExtension == "json" {
            do {
                let analysis = try await load(from: fileURL)

                // Filter by tag if provided
                if let tag = tag, !analysis.metadata.tags.contains(tag) {
                    continue
                }

                analyses.append(AnalysisSummary(
                    url: fileURL,
                    filename: fileURL.lastPathComponent,
                    name: analysis.metadata.name,
                    timestamp: analysis.metadata.storedAt ?? analysis.metadata.analyzedAt,
                    complexityScore: analysis.complexityScore,
                    tags: analysis.metadata.tags,
                    actionCount: analysis.actions.count,
                    slowActions: analysis.metrics.slowActions,
                    avgDuration: analysis.metrics.avgDuration
                ))
            } catch {
                // Skip corrupted files
                print("Warning: Skipping corrupted analysis file: \(fileURL.lastPathComponent)")
                continue
            }
        }

        // Sort
        switch sortBy {
        case .date:
            analyses.sort { $0.timestamp > $1.timestamp }
        case .name:
            analyses.sort { $0.name < $1.name }
        case .complexity:
            analyses.sort { $0.complexityScore > $1.complexityScore }
        }

        if let limit = limit {
            return Array(analyses.prefix(limit))
        }

        return analyses
    }

    /// Find analyses by name pattern
    func findAnalyses(namePattern: String) async throws -> [AnalysisSummary] {
        let allAnalyses = try await listAnalyses()
        return allAnalyses.filter { summary in
            summary.name.localizedCaseInsensitiveContains(namePattern)
        }
    }

    /// Delete analysis by filename
    func delete(filename: String) throws {
        let fileURL = storageDirectory.appendingPathComponent(filename)
        try FileManager.default.removeItem(at: fileURL)
    }

    /// Get storage statistics
    func getStorageStats() async throws -> StorageStats {
        let contents = try FileManager.default.contentsOfDirectory(
            at: storageDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .creationDateKey]
        )

        let jsonFiles = contents.filter { $0.pathExtension == "json" }
        let totalSize = jsonFiles.compactMap { url in
            try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        }.reduce(0, +)

        let oldestDate = jsonFiles.compactMap { url in
            try? url.resourceValues(forKeys: [.creationDateKey]).creationDate
        }.min()

        let newestDate = jsonFiles.compactMap { url in
            try? url.resourceValues(forKeys: [.creationDateKey]).creationDate
        }.max()

        return StorageStats(
            totalAnalyses: jsonFiles.count,
            totalSizeBytes: totalSize,
            oldestAnalysis: oldestDate,
            newestAnalysis: newestDate
        )
    }

    /// Cleanup old analyses
    func cleanupOldAnalyses(olderThan days: Int) async throws -> Int {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let analyses = try await listAnalyses()

        var deletedCount = 0
        for analysis in analyses {
            if analysis.timestamp < cutoffDate {
                try delete(filename: analysis.filename)
                deletedCount += 1
            }
        }

        return deletedCount
    }

    enum SortBy {
        case date
        case name
        case complexity
    }
}

/// Summary of a stored analysis
struct AnalysisSummary: Codable, Sendable {
    let url: URL
    let filename: String
    let name: String
    let timestamp: Date
    let complexityScore: Double
    let tags: [String]
    let actionCount: Int
    let slowActions: Int
    let avgDuration: Double

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var complexityRating: String {
        switch complexityScore {
        case 0..<25: return "🟢 Excellent"
        case 25..<50: return "🟡 Good"
        case 50..<75: return "🟠 Fair"
        default: return "🔴 Poor"
        }
    }

    var avgDurationMS: Double {
        avgDuration * 1000
    }
}

/// Storage statistics
struct StorageStats: Codable, Sendable {
    let totalAnalyses: Int
    let totalSizeBytes: Int
    let oldestAnalysis: Date?
    let newestAnalysis: Date?

    var totalSizeMB: Double {
        Double(totalSizeBytes) / (1024 * 1024)
    }

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalSizeBytes))
    }
}