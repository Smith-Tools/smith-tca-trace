import Foundation

/// Calculates complexity scores for TCA traces
@available(macOS 14, *)
struct ComplexityScorer: Sendable {
    /// Calculate complexity score (0-100)
    /// Based on: slow actions %, avg duration, shared state changes, render triggers
    func calculateScore(
        metrics: PerformanceMetrics,
        sharedStateChanges: Int,
        renderTriggers: Int
    ) -> Double {
        let slowActionsPct = Double(metrics.slowActions) / Double(max(metrics.totalActions, 1))
        let avgDurationPenalty = min(metrics.avgDuration / 0.016, 1.0) // Normalized to 16ms
        let sharedStatePenalty = min(Double(sharedStateChanges) / 10.0, 1.0) // Normalized to 10 changes
        let renderPenalty = min(Double(renderTriggers) / 5.0, 1.0) // Normalized to 5 renders

        let score = min(100.0,
            (slowActionsPct * 40.0) +      // 40% weight
            (avgDurationPenalty * 30.0) +  // 30% weight
            (sharedStatePenalty * 15.0) +  // 15% weight
            (renderPenalty * 15.0)         // 15% weight
        )

        return score
    }

    /// Get complexity rating with emoji
    func getComplexityRating(_ score: Double) -> (rating: String, emoji: String, color: String) {
        switch score {
        case 0..<25:
            return ("Excellent", "🟢", "green")
        case 25..<50:
            return ("Good", "🟡", "yellow")
        case 50..<75:
            return ("Fair", "🟠", "orange")
        default:
            return ("Poor", "🔴", "red")
        }
    }

    /// Calculate feature complexity score
    func calculateFeatureComplexity(_ featureMetrics: FeatureMetrics) -> Double {
        let slowActionRatio = Double(featureMetrics.slowActions) / Double(max(featureMetrics.actionCount, 1))
        let avgDurationPenalty = min(featureMetrics.avgDuration / 0.016, 1.0)

        return min(100.0, (slowActionRatio * 60.0) + (avgDurationPenalty * 40.0))
    }
}