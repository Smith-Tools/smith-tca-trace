import Foundation

/// Markdown formatting for different output modes
@available(macOS 14, *)
struct MarkdownFormatter: Sendable {
    /// Format user-friendly markdown with emojis
    static func formatUserMarkdown(_ analysis: TraceAnalysis, suppressSummary: Bool = false) -> String {
        let scorer = ComplexityScorer()
        let complexityRating = scorer.getComplexityRating(analysis.complexityScore)

        // Extract worst action
        let worstAction = analysis.actions.max { $0.duration < $1.duration }
        let worstActionStr = worstAction.map { "**\($0.fullName)**: \(String(format: "%.1f", $0.durationMS))ms" } ?? "—"

        // Extract worst effect
        let worstEffect = analysis.effects.max { $0.duration < $1.duration }
        let worstEffectStr = worstEffect.map { "**\($0.name)**: \(String(format: "%.0f", $0.durationMS))ms" } ?? "—"

        // Count long effects (> 500ms)
        let longEffectsCount = analysis.effects.filter { $0.isLongRunning }.count

        // Extract top feature (by max action duration)
        let topFeatureName = analysis.metrics.features
            .max { (lhs, rhs) in
                let lhsMaxDuration = analysis.actions
                    .filter { $0.featureName == lhs.key }
                    .map { $0.duration }
                    .max() ?? 0
                let rhsMaxDuration = analysis.actions
                    .filter { $0.featureName == rhs.key }
                    .map { $0.duration }
                    .max() ?? 0
                return lhsMaxDuration < rhsMaxDuration
            }
            .map { $0.key } ?? "—"

        var markdown = """
        # TCA Performance Analysis

        ## Summary
        - **📱 App**: \(analysis.metadata.name)
        - **⏱️  Duration**: \(String(format: "%.1f", analysis.duration))s
        - **🎯 Actions**: \(analysis.actions.count) (\(analysis.metrics.slowActions) slow)
        - **📊 Complexity**: \(String(format: "%.0f", analysis.complexityScore))/100 \(complexityRating.emoji)
        - **⚡ Avg Duration**: \(String(format: "%.1f", analysis.metrics.avgDuration * 1000))ms
        - **🔥 Max Duration**: \(String(format: "%.1f", analysis.metrics.maxDuration * 1000))ms

        """

        if !suppressSummary {
            markdown += """
            ### Key Findings
            - **🔴 Worst Action**: \(worstActionStr)
            - **⏱️  Worst Effect**: \(worstEffectStr)
            - **📌 Long Effects**: \(longEffectsCount) effect(s) >500ms
            - **🏆 Top Feature**: \(topFeatureName)

            """
        }

        // Slow Actions section
        let slowActions = analysis.actions.filter { $0.isSlowFor60FPS }.sorted { $0.duration > $1.duration }
        if !slowActions.isEmpty {
            markdown += """
            ## 🐌 Slow Actions (>16ms)

            """
            for action in slowActions.prefix(10) {
                if action.hasEnrichment {
                    markdown += "- **\(action.fullName)**: \(String(format: "%.1f", action.durationMS))ms | \(action.enrichmentSummary)\n"
                } else {
                    markdown += "- **\(action.fullName)**: \(String(format: "%.1f", action.durationMS))ms\n"
                }
            }
        }

        // Top Features section
        if !analysis.metrics.features.isEmpty {
            markdown += "\n## 🏗️  Top Features by Activity\n\n"
            let topFeatures = analysis.metrics.features.sorted { $0.value.actionCount > $1.value.actionCount }.prefix(5)
            for (name, metrics) in topFeatures {
                let slowPct = metrics.actionCount > 0 ? Int((Double(metrics.slowActions) / Double(metrics.actionCount)) * 100) : 0
                markdown += "- **\(name)**: \(metrics.actionCount) actions (\(slowPct)% slow), avg \(String(format: "%.1f", metrics.avgDurationMS))ms\n"
            }
        }

        // Effects section
        let longEffects = analysis.effects.filter { $0.isLongRunning }
        if !longEffects.isEmpty {
            markdown += "\n## ⏱️  Long-running Effects (>500ms)\n\n"
            for effect in longEffects.prefix(5) {
                if effect.hasEnrichment {
                    markdown += "- **\(effect.name)**: \(String(format: "%.0f", effect.durationMS))ms | \(effect.enrichmentSummary)\n"
                } else {
                    markdown += "- **\(effect.name)**: \(String(format: "%.0f", effect.durationMS))ms\n"
                }
            }
        }

        // Shared State Changes
        if !analysis.sharedStateChanges.isEmpty {
            markdown += "\n## 🔄 Shared State Changes\n\n"
            markdown += "- Total changes: \(analysis.sharedStateChanges.count)\n"

            let stateChangesByFeature = Dictionary(grouping: analysis.sharedStateChanges) { $0.featureName }
            let topChurn = stateChangesByFeature.sorted { $0.value.count > $1.value.count }.prefix(3)
            for (feature, changes) in topChurn {
                markdown += "- **\(feature)**: \(changes.count) changes\n"
            }
        }

        // Recommendations
        if !analysis.recommendations.isEmpty {
            markdown += "\n## 🎯 Recommendations\n\n"
            for recommendation in analysis.recommendations.prefix(8) {
                markdown += "\(recommendation)\n"
            }
        }

        return markdown
    }

    /// Format agent-focused markdown (more detailed)
    static func formatAgentMarkdown(_ analysis: TraceAnalysis, suppressSummary: Bool = false) -> String {
        // Extract worst action
        let worstAction = analysis.actions.max { $0.duration < $1.duration }
        let worstActionStr = worstAction.map { "**\($0.fullName)** (\($0.featureName)): \(String(format: "%.3f", $0.duration))s" } ?? "—"

        // Extract worst effect
        let worstEffect = analysis.effects.max { $0.duration < $1.duration }
        let worstEffectStr = worstEffect.map { "**\($0.name)**: \(String(format: "%.3f", $0.duration))s" } ?? "—"

        // Count long effects (> 500ms)
        let longEffectsCount = analysis.effects.filter { $0.isLongRunning }.count

        var markdown = """
        # TCA Performance Analysis (Agent Mode)

        ## Metadata
        - **Name**: \(analysis.metadata.name)
        - **Trace Path**: \(analysis.metadata.tracePath)
        - **Analyzed**: \(ISO8601DateFormatter().string(from: analysis.metadata.analyzedAt))
        - **Duration**: \(String(format: "%.3f", analysis.duration))s
        - **Complexity Score**: \(String(format: "%.1f", analysis.complexityScore))/100

        """

        if !suppressSummary {
            markdown += """
            ## Summary
            - **Worst Action**: \(worstActionStr)
            - **Worst Effect**: \(worstEffectStr)
            - **Long Effects**: \(longEffectsCount) effect(s) >500ms

            """
        }

        markdown += """
        ## Performance Metrics
        - **Total Actions**: \(analysis.metrics.totalActions)
        - **Slow Actions**: \(analysis.metrics.slowActions) (\(String(format: "%.1f", (Double(analysis.metrics.slowActions) / Double(max(analysis.metrics.totalActions, 1))) * 100))%)
        - **Avg Duration**: \(String(format: "%.3f", analysis.metrics.avgDuration))s
        - **Max Duration**: \(String(format: "%.3f", analysis.metrics.maxDuration))s
        - **Min Duration**: \(String(format: "%.3f", analysis.metrics.minDuration))s

        ## Feature Breakdown
        """

        for (name, metrics) in analysis.metrics.features.sorted(by: { $0.value.actionCount > $1.value.actionCount }) {
            markdown += """

            ### \(name)
            - Actions: \(metrics.actionCount)
            - Slow: \(metrics.slowActions) (\(String(format: "%.1f", (Double(metrics.slowActions) / Double(max(metrics.actionCount, 1))) * 100))%)
            - Avg Duration: \(String(format: "%.3f", metrics.avgDuration))s
            - Max Duration: \(String(format: "%.3f", metrics.maxDuration))s
            - Total Time: \(String(format: "%.3f", metrics.totalDuration))s
            """
        }

        if !analysis.recommendations.isEmpty {
            markdown += "\n\n## Recommendations\n\n"
            for (index, recommendation) in analysis.recommendations.enumerated() {
                markdown += "\(index + 1). \(recommendation)\n"
            }
        }

        return markdown
    }

    /// Format compact markdown (token-optimized)
    static func formatCompactMarkdown(_ analysis: TraceAnalysis) -> String {
        let slowActions = analysis.actions.filter { $0.isSlowFor60FPS }.sorted { $0.duration > $1.duration }.prefix(5)
        let topFeatures = analysis.metrics.features.sorted { $0.value.actionCount > $1.value.actionCount }.prefix(3)

        var markdown = """
        TCA Analysis: \(analysis.metadata.name)
        Score: \(String(format: "%.0f", analysis.complexityScore))/100 | Actions: \(analysis.actions.count) (\(analysis.metrics.slowActions) slow) | Avg: \(String(format: "%.1f", analysis.metrics.avgDuration * 1000))ms

        Slow Actions:
        """

        for action in slowActions {
            if action.hasEnrichment {
                markdown += "\n• \(action.fullName): \(String(format: "%.1f", action.durationMS))ms | \(action.enrichmentSummary)"
            } else {
                markdown += "\n• \(action.fullName): \(String(format: "%.1f", action.durationMS))ms"
            }
        }

        if !topFeatures.isEmpty {
            markdown += "\n\nTop Features:"
            for (name, metrics) in topFeatures {
                markdown += "\n• \(name): \(metrics.actionCount) actions, \(String(format: "%.1f", metrics.avgDurationMS))ms avg"
            }
        }

        if !analysis.recommendations.isEmpty {
            markdown += "\n\nKey Recommendations:"
            for recommendation in analysis.recommendations.prefix(3) {
                markdown += "\n• \(recommendation)"
            }
        }

        return markdown
    }

    /// Format comparison result as markdown
    static func formatComparisonMarkdown(_ comparison: ComparisonResult) -> String {
        var markdown = """
        # TCA Performance Comparison

        ## Summary
        **Baseline**: \(comparison.baseline.name)
        **Current**: \(comparison.current.name)
        **Complexity Change**: \(String(format: "%+.1f", comparison.complexityChange))

        """

        if !comparison.regressions.isEmpty {
            markdown += "## 🔴 Regressions\n\n"
            for regression in comparison.regressions.prefix(10) {
                markdown += "- **\(regression.actionName)**: \(String(format: "%.1f", regression.baselineDuration * 1000))ms → \(String(format: "%.1f", regression.currentDuration * 1000))ms (\(String(format: "+%.0f", regression.percentChange))%) \(regression.severity.rawValue)\n"
            }
        }

        if !comparison.improvements.isEmpty {
            markdown += "\n## ✅ Improvements\n\n"
            for improvement in comparison.improvements.prefix(10) {
                markdown += "- **\(improvement.actionName)**: \(String(format: "%.1f", improvement.baselineDuration * 1000))ms → \(String(format: "%.1f", improvement.currentDuration * 1000))ms (\(String(format: "-%.0f", improvement.percentChange))%) \(improvement.significance.rawValue)\n"
            }
        }

        let perfChange = comparison.performanceChange
        markdown += """

        ## 📊 Performance Summary
        - **Total Regressions**: \(perfChange.totalRegressions)
        - **Total Improvements**: \(perfChange.totalImprovements)
        - **Avg Regression**: \(String(format: "+%.0f", perfChange.avgRegressionPercent))%
        - **Max Regression**: \(String(format: "+%.0f", perfChange.maxRegressionPercent))%
        - **Avg Improvement**: \(String(format: "-%.0f", perfChange.avgImprovementPercent))%
        """

        return markdown
    }
}