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

    private enum CodingKeys: String, CodingKey {
        case featureName, actionName, timestamp, duration, metadata
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

    var durationMS: Double {
        duration * 1000
    }

    var isLongRunning: Bool {
        duration > 0.5  // 500ms threshold
    }

    private enum CodingKeys: String, CodingKey {
        case name, featureName, startTime, endTime
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