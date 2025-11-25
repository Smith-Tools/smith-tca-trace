import Foundation

/// JSON formatting for different output modes
@available(macOS 14, *)
struct JSONFormatter: Sendable {
    /// Round a Double to specified decimal places
    private static func roundToDecimal(_ value: Double, places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (value * multiplier).rounded() / multiplier
    }
    /// Format full JSON for agent mode (complete data)
    static func formatFullAgentJSON(_ analysis: TraceAnalysis) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]  // Sorted but not pretty
        encoder.dateEncodingStrategy = .iso8601
        let data = try! encoder.encode(analysis)
        return String(data: data, encoding: .utf8)!
    }

    /// Format compact JSON for AI agents (30-40% token reduction)
    static func formatCompactAgentJSON(_ analysis: TraceAnalysis) -> String {
        let compact = CompactAnalysis(
            // Summary (always included - small footprint)
            summary: CompactAnalysis.Summary(
                totalActions: analysis.actions.count,
                slowActionsCount: analysis.actions.filter { $0.isSlowFor60FPS }.count,
                complexityScore: Self.roundToDecimal(analysis.complexityScore, places: 1),
                avgDuration: Self.roundToDecimal(analysis.metrics.avgDuration * 1000, places: 1), // ms
                maxDuration: Self.roundToDecimal(analysis.metrics.maxDuration * 1000, places: 1),  // ms
                duration: Self.roundToDecimal(analysis.duration, places: 1)
            ),
            // Top 10 slowest actions only (not all actions)
            slowActions: analysis.actions
                .filter { $0.isSlowFor60FPS }
                .sorted { $0.duration > $1.duration }
                .prefix(10)
                .map { CompactAnalysis.CompactAction(
                    feature: $0.featureName,
                    action: $0.actionName,
                    duration: Self.roundToDecimal($0.duration * 1000, places: 1) // ms
                )},
            // Top 5 features by action count
            features: analysis.metrics.features
                .sorted { $0.value.actionCount > $1.value.actionCount }
                .prefix(5)
                .map { (name, metrics) in
                    CompactAnalysis.CompactFeature(
                        name: name,
                        actions: metrics.actionCount,
                        slowActions: metrics.slowActions,
                        avgDuration: Self.roundToDecimal(metrics.avgDuration * 1000, places: 1)
                    )
                },
            // Long-running effects only (>100ms)
            longEffects: analysis.effects
                .filter { $0.duration > 0.1 }
                .sorted { $0.duration > $1.duration }
                .prefix(5)
                .map { CompactAnalysis.CompactEffect(
                    name: $0.name,
                    duration: Self.roundToDecimal($0.duration * 1000, places: 0) // ms, no decimals
                )},
            // Recommendations (always valuable)
            recommendations: Array(analysis.recommendations.prefix(6)),
            // Metadata for comparison
            meta: CompactAnalysis.CompactMeta(
                name: analysis.metadata.name,
                analyzedAt: ISO8601DateFormatter().string(from: analysis.metadata.analyzedAt)
            )
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = []  // Compact JSON (no whitespace)
        let data = try! encoder.encode(compact)
        return String(data: data, encoding: .utf8)!
    }

    /// Format user-friendly JSON
    static func formatUserJSON(_ analysis: TraceAnalysis) -> String {
        let user = UserAnalysis(
            summary: UserAnalysis.Summary(
                name: analysis.metadata.name,
                complexityScore: analysis.complexityScore,
                complexityRating: getComplexityRating(analysis.complexityScore),
                totalActions: analysis.actions.count,
                slowActions: analysis.actions.filter { $0.isSlowFor60FPS }.count,
                avgDuration: analysis.metrics.avgDuration * 1000, // ms
                duration: analysis.duration
            ),
            slowActions: analysis.actions
                .filter { $0.isSlowFor60FPS }
                .sorted { $0.duration > $1.duration }
                .prefix(10)
                .map { UserAnalysis.SlowAction(
                    name: $0.fullName,
                    feature: $0.featureName,
                    duration: String(format: "%.1f", $0.durationMS)
                )},
            topFeatures: analysis.metrics.features
                .sorted { $0.value.actionCount > $1.value.actionCount }
                .prefix(5)
                .map { (name, metrics) in
                    UserAnalysis.TopFeature(
                        name: name,
                        actions: metrics.actionCount,
                        slowActions: metrics.slowActions,
                        avgDuration: String(format: "%.1f", metrics.avgDurationMS)
                    )
                },
            recommendations: analysis.recommendations
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try! encoder.encode(user)
        return String(data: data, encoding: .utf8)!
    }

    /// Format comparison result as JSON
    static func formatComparisonJSON(_ comparison: ComparisonResult) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try! encoder.encode(comparison)
        return String(data: data, encoding: .utf8)!
    }

    private static func getComplexityRating(_ score: Double) -> String {
        switch score {
        case 0..<25: return "🟢 Excellent"
        case 25..<50: return "🟡 Good"
        case 50..<75: return "🟠 Fair"
        default: return "🔴 Poor"
        }
    }
}

/// Compact data structures for token efficiency (used in compact mode)
struct CompactAnalysis: Codable, Sendable {
    let summary: Summary
    let slowActions: [CompactAction]
    let features: [CompactFeature]
    let longEffects: [CompactEffect]
    let recommendations: [String]
    let meta: CompactMeta

    struct Summary: Codable, Sendable {
        let totalActions: Int
        let slowActionsCount: Int
        let complexityScore: Double
        let avgDuration: Double  // ms
        let maxDuration: Double  // ms
        let duration: Double
    }

    struct CompactAction: Codable, Sendable {
        let feature: String
        let action: String
        let duration: Double  // ms
    }

    struct CompactFeature: Codable, Sendable {
        let name: String
        let actions: Int
        let slowActions: Int
        let avgDuration: Double  // ms
    }

    struct CompactEffect: Codable, Sendable {
        let name: String
        let duration: Double  // ms
    }

    struct CompactMeta: Codable, Sendable {
        let name: String
        let analyzedAt: String
    }
}

/// User-friendly data structures
struct UserAnalysis: Codable, Sendable {
    let summary: Summary
    let slowActions: [SlowAction]
    let topFeatures: [TopFeature]
    let recommendations: [String]

    struct Summary: Codable, Sendable {
        let name: String
        let complexityScore: Double
        let complexityRating: String
        let totalActions: Int
        let slowActions: Int
        let avgDuration: Double  // ms
        let duration: Double
    }

    struct SlowAction: Codable, Sendable {
        let name: String
        let feature: String
        let duration: String  // formatted string
    }

    struct TopFeature: Codable, Sendable {
        let name: String
        let actions: Int
        let slowActions: Int
        let avgDuration: String  // formatted string
    }
}