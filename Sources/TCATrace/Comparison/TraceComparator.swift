import Foundation

/// Compares two TCA trace analyses and detects regressions/improvements
@available(macOS 14, *)
struct TraceComparator: Sendable {
    /// Compare two analyses and find differences
    func compare(
        baseline: TraceAnalysis,
        current: TraceAnalysis,
        threshold: Double = 20.0
    ) -> ComparisonResult {
        var regressions: [Regression] = []
        var improvements: [Improvement] = []

        // Compare by action name
        let baselineActions = Dictionary(grouping: baseline.actions) { "\($0.featureName).\($0.actionName)" }
        let currentActions = Dictionary(grouping: current.actions) { "\($0.featureName).\($0.actionName)" }

        for (actionKey, currentActionList) in currentActions {
            guard let baselineActionList = baselineActions[actionKey] else {
                // New action, skip comparison
                continue
            }

            let baselineAvg = baselineActionList.map(\.duration).reduce(0, +) / Double(baselineActionList.count)
            let currentAvg = currentActionList.map(\.duration).reduce(0, +) / Double(currentActionList.count)

            let percentChange = ((currentAvg - baselineAvg) / baselineAvg) * 100

            if percentChange > threshold {
                regressions.append(Regression(
                    actionName: actionKey,
                    baselineDuration: baselineAvg,
                    currentDuration: currentAvg,
                    percentChange: percentChange
                ))
            } else if percentChange < -threshold {
                improvements.append(Improvement(
                    actionName: actionKey,
                    baselineDuration: baselineAvg,
                    currentDuration: currentAvg,
                    percentChange: abs(percentChange)
                ))
            }
        }

        return ComparisonResult(
            baseline: baseline.metadata,
            current: current.metadata,
            regressions: regressions.sorted { $0.percentChange > $1.percentChange },
            improvements: improvements.sorted { $0.percentChange > $1.percentChange },
            complexityChange: current.complexityScore - baseline.complexityScore
        )
    }

    /// Get performance summary between two traces
    func getPerformanceSummary(
        baseline: TraceAnalysis,
        current: TraceAnalysis
    ) -> PerformanceSummary {
        let baselineMetrics = baseline.metrics
        let currentMetrics = current.metrics

        return PerformanceSummary(
            totalActionsChange: currentMetrics.totalActions - baselineMetrics.totalActions,
            slowActionsChange: currentMetrics.slowActions - baselineMetrics.slowActions,
            avgDurationChange: currentMetrics.avgDuration - baselineMetrics.avgDuration,
            maxDurationChange: currentMetrics.maxDuration - baselineMetrics.maxDuration,
            newFeatures: Set(currentMetrics.features.keys).subtracting(Set(baselineMetrics.features.keys)),
            removedFeatures: Set(baselineMetrics.features.keys).subtracting(Set(currentMetrics.features.keys))
        )
    }

    /// Compare feature-by-feature metrics
    func compareFeatures(
        baseline: TraceAnalysis,
        current: TraceAnalysis
    ) -> [FeatureComparison] {
        let baselineFeatures = baseline.metrics.features
        let currentFeatures = current.metrics.features
        let allFeatures = Set(baselineFeatures.keys).union(Set(currentFeatures.keys))

        return allFeatures.sorted().map { featureName in
            let baselineMetrics = baselineFeatures[featureName]
            let currentMetrics = currentFeatures[featureName]

            return FeatureComparison(
                featureName: featureName,
                baseline: baselineMetrics,
                current: currentMetrics
            )
        }
    }
}

/// Summary of performance changes
struct PerformanceSummary: Codable, Sendable {
    let totalActionsChange: Int
    let slowActionsChange: Int
    let avgDurationChange: Double
    let maxDurationChange: Double
    let newFeatures: Set<String>
    let removedFeatures: Set<String>

    var formattedSummary: String {
        var parts: [String] = []

        if totalActionsChange != 0 {
            let arrow = totalActionsChange > 0 ? "↗️" : "↘️"
            parts.append("\(arrow) \(abs(totalActionsChange)) actions")
        }

        if slowActionsChange != 0 {
            let arrow = slowActionsChange > 0 ? "🔴" : "🟢"
            parts.append("\(arrow) \(abs(slowActionsChange)) slow actions")
        }

        if avgDurationChange != 0 {
            let arrow = avgDurationChange > 0 ? "⬆️" : "⬇️"
            let change = String(format: "%.1f", abs(avgDurationChange * 1000))
            parts.append("\(arrow) \(change)ms avg duration")
        }

        if !newFeatures.isEmpty {
            parts.append("➕ \(newFeatures.count) new features")
        }

        if !removedFeatures.isEmpty {
            parts.append("➖ \(removedFeatures.count) removed features")
        }

        return parts.isEmpty ? "No significant changes" : parts.joined(separator: ", ")
    }
}

/// Comparison of a single feature between two traces
struct FeatureComparison: Codable, Sendable {
    let featureName: String
    let baseline: FeatureMetrics?
    let current: FeatureMetrics?

    var actionCountChange: Int {
        (current?.actionCount ?? 0) - (baseline?.actionCount ?? 0)
    }

    var avgDurationChange: Double {
        (current?.avgDuration ?? 0) - (baseline?.avgDuration ?? 0)
    }

    var status: FeatureStatus {
        guard let current = current else { return .removed }
        guard let baseline = baseline else { return .new }

        let change = ((current.avgDuration - baseline.avgDuration) / baseline.avgDuration) * 100

        if abs(change) < 5 {
            return .stable
        } else if change > 20 {
            return .regressed
        } else if change < -20 {
            return .improved
        } else {
            return .changed
        }
    }

    enum FeatureStatus: String, Codable, CaseIterable {
        case new = "🆕"
        case removed = "❌"
        case improved = "✅"
        case regressed = "🔴"
        case changed = "🔄"
        case stable = "⚖️"
    }
}