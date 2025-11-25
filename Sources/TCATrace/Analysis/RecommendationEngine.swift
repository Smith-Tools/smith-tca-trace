import Foundation

/// Generates actionable recommendations based on TCA trace analysis
@available(macOS 14, *)
struct RecommendationEngine: Sendable {
    /// Generate actionable recommendations based on analysis
    func generateRecommendations(for analysis: TraceAnalysis) -> [String] {
        var recommendations: [String] = []

        // High complexity recommendations
        generateComplexityRecommendations(analysis, &recommendations)

        // Performance recommendations
        generatePerformanceRecommendations(analysis, &recommendations)

        // Shared state recommendations
        generateSharedStateRecommendations(analysis, &recommendations)

        // Effect recommendations
        generateEffectRecommendations(analysis, &recommendations)

        // Feature-specific recommendations
        generateFeatureRecommendations(analysis, &recommendations)

        return Array(recommendations.prefix(8)) // Limit to 8 most impactful recommendations
    }

    private func generateComplexityRecommendations(_ analysis: TraceAnalysis, _ recommendations: inout [String]) {
        if analysis.complexityScore > 70 {
            recommendations.append("⚠️ High complexity score (\(String(format: "%.0f", analysis.complexityScore))/100). Consider decomposing features or simplifying action chains.")
        }

        if analysis.complexityScore > 50 && analysis.actions.count > 50 {
            recommendations.append("📊 Many actions detected (\(analysis.actions.count)). Consider breaking down complex interactions into smaller, focused features.")
        }

        if analysis.metrics.features.count > 10 {
            recommendations.append("🏗️ High feature coupling detected (\(analysis.metrics.features.count) features). Consider isolating features to reduce shared dependencies.")
        }
    }

    private func generatePerformanceRecommendations(_ analysis: TraceAnalysis, _ recommendations: inout [String]) {
        // Slow actions
        let slowActions = analysis.actions.filter { $0.isSlowFor60FPS }.sorted { $0.duration > $1.duration }

        if !slowActions.isEmpty {
            let topSlowActions = Array(slowActions.prefix(3))
            recommendations.append("🐌 \(slowActions.count) slow actions detected (>16ms). Consider optimizing:")

            for action in topSlowActions {
                let duration = String(format: "%.1f", action.durationMS)
                recommendations.append("   • \(action.fullName): \(duration)ms - move work to background or break into smaller actions")
            }
        }

        // High variance in action times
        let durations = analysis.actions.map(\.duration)
        if !durations.isEmpty {
            let avg = durations.reduce(0, +) / Double(durations.count)
            let stdDev = sqrt(durations.map { pow($0 - avg, 2) }.reduce(0, +) / Double(durations.count))

            if stdDev > avg * 0.5 {
                recommendations.append("📈 High variance in action execution times. Consider standardizing action patterns and adding timeouts.")
            }
        }
    }

    private func generateSharedStateRecommendations(_ analysis: TraceAnalysis, _ recommendations: inout [String]) {
        if analysis.sharedStateChanges.count > 15 {
            recommendations.append("🔄 Excessive shared state changes (\(analysis.sharedStateChanges.count)). Consider consolidating related state updates or using derived state.")
        }

        // Group state changes by feature
        let featureStateChanges = Dictionary(grouping: analysis.sharedStateChanges) { $0.featureName }
        let highChurnFeatures = featureStateChanges.filter { $0.value.count > 5 }

        for (feature, changes) in highChurnFeatures.prefix(2) {
            recommendations.append("⚡ High state churn in \(feature) (\(changes.count) changes). Consider batching updates or using local state.")
        }
    }

    private func generateEffectRecommendations(_ analysis: TraceAnalysis, _ recommendations: inout [String]) {
        let longEffects = analysis.effects.filter { $0.isLongRunning }

        if !longEffects.isEmpty {
            recommendations.append("⏱️ \(longEffects.count) long-running effects (>500ms) detected:")

            for effect in Array(longEffects.prefix(2)) {
                let duration = String(format: "%.0f", effect.durationMS)
                recommendations.append("   • \(effect.name): \(duration)ms - monitor for potential cancellation issues")
            }
        }

        let overlappingEffects = findOverlappingEffects(analysis.effects)
        if !overlappingEffects.isEmpty {
            recommendations.append("🔀 \(overlappingEffects.count) overlapping effects detected. Consider using effect cancellation to prevent race conditions.")
        }
    }

    private func generateFeatureRecommendations(_ analysis: TraceAnalysis, _ recommendations: inout [String]) {
        // Find most problematic features
        let featureComplexities = analysis.metrics.features.map { (name, metrics) in
            (name: name, complexity: calculateFeatureComplexity(metrics))
        }.sorted { $0.complexity > $1.complexity }

        if let worstFeature = featureComplexities.first {
            if worstFeature.complexity > 60 {
                recommendations.append("🎯 Most complex feature: \(worstFeature.name) (complexity: \(String(format: "%.0f", worstFeature.complexity))/100). Focus optimization efforts here.")
            }
        }

        // Recommend specific architectural patterns based on analysis
        if Double(analysis.sharedStateChanges.count) > Double(analysis.actions.count) * 0.3 {
            recommendations.append("🏛️ Consider implementing the State Reducers pattern to centralize state mutations.")
        }

        if Double(analysis.effects.count) > Double(analysis.actions.count) * 0.5 {
            recommendations.append("🔄 Consider implementing Effect Cancellation to manage concurrent effects.")
        }
    }

    private func findOverlappingEffects(_ effects: [TCAEffect]) -> [(effect1: TCAEffect, effect2: TCAEffect)] {
        var overlapping: [(TCAEffect, TCAEffect)] = []
        let sortedEffects = effects.sorted { $0.startTime < $1.startTime }

        for i in 0..<sortedEffects.count {
            for j in (i + 1)..<sortedEffects.count {
                let effect1 = sortedEffects[i]
                let effect2 = sortedEffects[j]

                if effect1.endTime > effect2.startTime {
                    overlapping.append((effect1, effect2))
                } else {
                    break // No more overlaps possible
                }
            }
        }

        return overlapping
    }

    private func calculateFeatureComplexity(_ metrics: FeatureMetrics) -> Double {
        let slowActionRatio = Double(metrics.slowActions) / Double(max(metrics.actionCount, 1))
        let avgDurationPenalty = min(metrics.avgDuration / 0.016, 1.0)

        return min(100.0, (slowActionRatio * 60.0) + (avgDurationPenalty * 40.0))
    }
}