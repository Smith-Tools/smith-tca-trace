import Foundation

/// Raw signpost event data extracted from Instruments traces
struct SignpostEvent: Codable, Sendable, Identifiable {
    let id: String
    let timestamp: Double  // seconds since trace start
    let subsystem: String  // e.g. "com.scroll.app"
    let category: String   // e.g. "TCA"
    let name: String       // e.g. "ReadingLibraryFeature.selectArticle"
    let message: String    // Additional metadata
    let type: EventType    // begin, end, event

    enum EventType: String, Codable {
        case begin, end, event
    }
}

/// TCA-specific action extracted from signpost events
struct TCAAction: Codable, Sendable, Identifiable {
    let id = UUID()
    let featureName: String     // "ReadingLibrary"
    let actionName: String      // "selectArticle"
    let timestamp: Double       // seconds since trace start
    let duration: Double        // seconds
    let metadata: String?       // Additional info

    // Multi-instrument enrichment fields (optional)
    var topSymbols: [CPUSymbol] = []
    var waitState: String = ""
    var allocationDelta: Int64 = 0

    private enum CodingKeys: String, CodingKey {
        case featureName, actionName, timestamp, duration, metadata
        case topSymbols, waitState, allocationDelta
    }

    var fullName: String {
        "\(featureName).\(actionName)"
    }

    var isSlowFor60FPS: Bool {
        duration > 0.016  // 16ms threshold
    }

    var durationMS: Double {
        duration * 1000
    }

    var hasEnrichment: Bool {
        !topSymbols.isEmpty || !waitState.isEmpty || allocationDelta != 0
    }

    var enrichmentSummary: String {
        var parts: [String] = []

        if !topSymbols.isEmpty {
            parts.append("CPU: \(topSymbols.prefix(3).map { "\($0.symbolName)(\(String(format: "%.0f", $0.percent))%)" }.joined(separator: ", "))")
        }

        if !waitState.isEmpty && waitState != "cpu" {
            parts.append("Wait: \(waitState)")
        }

        if allocationDelta != 0 {
            let sign = allocationDelta > 0 ? "+" : ""
            let formatter = ByteCountFormatter()
            parts.append("Alloc: \(sign)\(formatter.string(fromByteCount: allocationDelta))")
        }

        return parts.joined(separator: " | ")
    }
}

/// CPU symbol information from profiler enrichment
struct CPUSymbol: Codable, Sendable, Identifiable {
    let id = UUID()
    let symbolName: String
    let moduleName: String?
    let percent: Double

    private enum CodingKeys: String, CodingKey {
        case symbolName, moduleName, percent
    }
}

/// TCA effect lifecycle information
struct TCAEffect: Codable, Sendable, Identifiable {
    let id = UUID()
    let name: String
    let featureName: String
    let startTime: Double
    let endTime: Double
    var duration: Double {
        endTime - startTime
    }

    // Multi-instrument enrichment fields (optional)
    var topSymbols: [CPUSymbol] = []
    var waitState: String = ""
    var allocationDelta: Int64 = 0

    var durationMS: Double {
        duration * 1000
    }

    var isLongRunning: Bool {
        duration > 0.5  // 500ms threshold
    }

    var hasEnrichment: Bool {
        !topSymbols.isEmpty || !waitState.isEmpty || allocationDelta != 0
    }

    var enrichmentSummary: String {
        var parts: [String] = []

        if !topSymbols.isEmpty {
            parts.append("CPU: \(topSymbols.prefix(3).map { "\($0.symbolName)(\(String(format: "%.0f", $0.percent))%)" }.joined(separator: ", "))")
        }

        if !waitState.isEmpty && waitState != "cpu" {
            parts.append("Wait: \(waitState)")
        }

        if allocationDelta != 0 {
            let sign = allocationDelta > 0 ? "+" : ""
            let formatter = ByteCountFormatter()
            parts.append("Alloc: \(sign)\(formatter.string(fromByteCount: allocationDelta))")
        }

        return parts.joined(separator: " | ")
    }

    private enum CodingKeys: String, CodingKey {
        case name, featureName, startTime, endTime
        case topSymbols, waitState, allocationDelta
    }
}

/// Shared state change event
struct SharedStateChange: Codable, Sendable, Identifiable {
    let id = UUID()
    let featureName: String
    let timestamp: Double
    let property: String
    let oldValue: String?
    let newValue: String?

    private enum CodingKeys: String, CodingKey {
        case featureName, timestamp, property, oldValue, newValue
    }
}