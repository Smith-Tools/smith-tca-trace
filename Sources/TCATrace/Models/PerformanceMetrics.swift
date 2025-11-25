import Foundation

/// Performance metrics calculated from TCA actions
struct PerformanceMetrics: Codable, Sendable {
    let totalActions: Int
    let slowActions: Int
    let avgDuration: Double
    let maxDuration: Double
    let minDuration: Double
    let features: [String: FeatureMetrics]

    init(actions: [TCAAction]) {
        self.totalActions = actions.count
        self.slowActions = actions.filter { $0.isSlowFor60FPS }.count

        let durations = actions.map(\.duration)
        self.avgDuration = durations.isEmpty ? 0 : durations.reduce(0, +) / Double(durations.count)
        self.maxDuration = durations.max() ?? 0
        self.minDuration = durations.min() ?? 0

        // Group actions by feature
        let grouped = Dictionary(grouping: actions) { $0.featureName }
        self.features = grouped.mapValues { featureActions in
            FeatureMetrics(actions: featureActions)
        }
    }
}

/// Performance metrics for a specific feature
struct FeatureMetrics: Codable, Sendable {
    let actionCount: Int
    let slowActions: Int
    let avgDuration: Double
    let maxDuration: Double
    let totalDuration: Double

    init(actions: [TCAAction]) {
        self.actionCount = actions.count
        self.slowActions = actions.filter { $0.isSlowFor60FPS }.count

        let durations = actions.map(\.duration)
        self.avgDuration = durations.isEmpty ? 0 : durations.reduce(0, +) / Double(durations.count)
        self.maxDuration = durations.max() ?? 0
        self.totalDuration = durations.reduce(0, +)
    }

    var avgDurationMS: Double {
        avgDuration * 1000
    }

    var totalDurationMS: Double {
        totalDuration * 1000
    }
}