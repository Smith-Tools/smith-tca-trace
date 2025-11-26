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
        // Extract worst action (max duration)
        let worstAction = analysis.actions.max { $0.duration < $1.duration }
        let worstActionCompact = worstAction.map { action in
            CompactAnalysis.CompactAction(
                feature: action.featureName,
                action: action.actionName,
                duration: Self.roundToDecimal(action.duration * 1000, places: 1),
                enrichment: action.hasEnrichment ? CompactAnalysis.Enrichment(
                    topSymbols: action.topSymbols.prefix(3).map { symbol in
                        CompactAnalysis.CPUSymbol(symbol: symbol.symbolName, percent: Self.roundToDecimal(symbol.percent, places: 1))
                    },
                    waitState: action.waitState,
                    allocationDelta: action.allocationDelta
                ) : nil
            )
        }

        // Extract worst effect (max duration)
        let worstEffect = analysis.effects.max { $0.duration < $1.duration }
        let worstEffectCompact = worstEffect.map { effect in
            CompactAnalysis.CompactEffect(
                name: effect.name,
                feature: effect.featureName,
                duration: Self.roundToDecimal(effect.duration * 1000, places: 0),
                start: Self.roundToDecimal(effect.startTime, places: 2),
                enrichment: effect.hasEnrichment ? CompactAnalysis.Enrichment(
                    topSymbols: effect.topSymbols.prefix(3).map { symbol in
                        CompactAnalysis.CPUSymbol(symbol: symbol.symbolName, percent: Self.roundToDecimal(symbol.percent, places: 1))
                    },
                    waitState: effect.waitState,
                    allocationDelta: effect.allocationDelta
                ) : nil
            )
        }

        // Count long effects (> 500ms)
        let longEffectsCount = analysis.effects.filter { $0.duration > 0.5 }.count

        // Root-cause candidates: actions whose spawned effects are long
        let longEffects = analysis.effects.filter { $0.duration > 0.5 }
        let rootCauses = longEffects.prefix(5).map { eff in
            CompactAnalysis.RootCause(
                action: eff.name,
                feature: eff.featureName,
                effect: eff.name,
                effectDuration: Self.roundToDecimal(eff.duration * 1000, places: 1)
            )
        }

        // Action → Effect pairs (hotlist by effect duration)
        let actionEffectPairs = longEffects.sorted { $0.duration > $1.duration }.prefix(5).map { eff in
            // Try to find the originating action duration (same name/feature)
            let matchingAction = analysis.actions.first { $0.actionName == eff.name || $0.featureName == eff.featureName }
            return CompactAnalysis.ActionEffectPair(
                action: matchingAction?.actionName ?? eff.name,
                feature: eff.featureName,
                effect: eff.name,
                actionDuration: Self.roundToDecimal((matchingAction?.duration ?? 0) * 1000, places: 1),
                effectDuration: Self.roundToDecimal(eff.duration * 1000, places: 1)
            )
        }

        // Extract top feature (by max action duration in that feature)
        let topFeature = analysis.metrics.features
            .max { (lhs, rhs) in
                // Compare by slowest action in each feature
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
            .map { (name, metrics) in
                CompactAnalysis.CompactFeature(
                    name: name,
                    actions: metrics.actionCount,
                    slowActions: metrics.slowActions,
                    avgDuration: Self.roundToDecimal(metrics.avgDuration * 1000, places: 1)
                )
            }

        let compact = CompactAnalysis(
            // Summary (always included - small footprint)
            summary: CompactAnalysis.Summary(
                totalActions: analysis.actions.count,
                slowActionsCount: analysis.actions.filter { $0.isSlowFor60FPS }.count,
                longEffectsCount: longEffectsCount,
                complexityScore: Self.roundToDecimal(analysis.complexityScore, places: 1),
                avgDuration: Self.roundToDecimal(analysis.metrics.avgDuration * 1000, places: 1), // ms
                maxDuration: Self.roundToDecimal(analysis.metrics.maxDuration * 1000, places: 1),  // ms
                duration: Self.roundToDecimal(analysis.duration, places: 1),
                worstAction: worstActionCompact,
                worstEffect: worstEffectCompact,
                topFeature: topFeature
            ),
            // Top 10 slowest actions only (not all actions)
            slowActions: analysis.actions
                .filter { $0.isSlowFor60FPS }
                .sorted { $0.duration > $1.duration }
                .prefix(10)
                .map { action in
                    CompactAnalysis.CompactAction(
                        feature: action.featureName,
                        action: action.actionName,
                        duration: Self.roundToDecimal(action.duration * 1000, places: 1), // ms
                        enrichment: action.hasEnrichment ? CompactAnalysis.Enrichment(
                            topSymbols: action.topSymbols.prefix(3).map { symbol in
                                CompactAnalysis.CPUSymbol(symbol: symbol.symbolName, percent: Self.roundToDecimal(symbol.percent, places: 1))
                            },
                            waitState: action.waitState,
                            allocationDelta: action.allocationDelta
                        ) : nil
                    )
                },
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
                .map { effect in
                    CompactAnalysis.CompactEffect(
                        name: effect.name,
                        feature: effect.featureName,
                        duration: Self.roundToDecimal(effect.duration * 1000, places: 0), // ms, no decimals
                        start: Self.roundToDecimal(effect.startTime, places: 2),
                        enrichment: effect.hasEnrichment ? CompactAnalysis.Enrichment(
                            topSymbols: effect.topSymbols.prefix(3).map { symbol in
                                CompactAnalysis.CPUSymbol(symbol: symbol.symbolName, percent: Self.roundToDecimal(symbol.percent, places: 1))
                            },
                            waitState: effect.waitState,
                            allocationDelta: effect.allocationDelta
                        ) : nil
                    )
                },
            rootCauses: Array(rootCauses),
            actionEffectPairs: Array(actionEffectPairs),
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
                .map { action in
                    UserAnalysis.SlowAction(
                        name: action.fullName,
                        feature: action.featureName,
                        duration: String(format: "%.1f", action.durationMS),
                        enrichment: action.hasEnrichment ? UserAnalysis.Enrichment(
                            topSymbols: action.topSymbols.prefix(3).map { symbol in
                                UserAnalysis.CPUSymbol(symbol: symbol.symbolName, percent: symbol.percent)
                            },
                            waitState: action.waitState,
                            allocationDelta: action.allocationDelta,
                            summary: action.enrichmentSummary
                        ) : nil
                    )
                },
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
    let rootCauses: [RootCause]
    let actionEffectPairs: [ActionEffectPair]
    let recommendations: [String]
    let meta: CompactMeta

    struct Summary: Codable, Sendable {
        let totalActions: Int
        let slowActionsCount: Int
        let longEffectsCount: Int
        let complexityScore: Double
        let avgDuration: Double  // ms
        let maxDuration: Double  // ms
        let duration: Double
        let worstAction: CompactAction?
        let worstEffect: CompactEffect?
        let topFeature: CompactFeature?
    }

    struct CompactAction: Codable, Sendable {
        let feature: String
        let action: String
        let duration: Double  // ms
        let enrichment: Enrichment?  // Multi-instrument enrichment data

        init(feature: String, action: String, duration: Double, enrichment: Enrichment? = nil) {
            self.feature = feature
            self.action = action
            self.duration = duration
            self.enrichment = enrichment
        }
    }

    struct CompactFeature: Codable, Sendable {
        let name: String
        let actions: Int
        let slowActions: Int
        let avgDuration: Double  // ms
    }

    struct CompactEffect: Codable, Sendable {
        let name: String
        let feature: String?
        let duration: Double  // ms
        let start: Double?    // seconds (optional)
        let enrichment: Enrichment?  // Multi-instrument enrichment data

        init(name: String, feature: String?, duration: Double, start: Double?, enrichment: Enrichment? = nil) {
            self.name = name
            self.feature = feature
            self.duration = duration
            self.start = start
            self.enrichment = enrichment
        }
    }

    struct RootCause: Codable, Sendable {
        let action: String
        let feature: String
        let effect: String
        let effectDuration: Double  // ms
    }

    struct ActionEffectPair: Codable, Sendable {
        let action: String
        let feature: String
        let effect: String
        let actionDuration: Double  // ms
        let effectDuration: Double  // ms
    }

    struct CompactMeta: Codable, Sendable {
        let name: String
        let analyzedAt: String
    }

    /// Multi-instrument enrichment data for compact JSON output
    struct Enrichment: Codable, Sendable {
        let topSymbols: [CPUSymbol]
        let waitState: String
        let allocationDelta: Int64
    }

    /// CPU symbol information for compact output
    struct CPUSymbol: Codable, Sendable {
        let symbol: String
        let percent: Double
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
        let enrichment: Enrichment?  // Multi-instrument enrichment data

        init(name: String, feature: String, duration: String, enrichment: Enrichment? = nil) {
            self.name = name
            self.feature = feature
            self.duration = duration
            self.enrichment = enrichment
        }
    }

    struct TopFeature: Codable, Sendable {
        let name: String
        let actions: Int
        let slowActions: Int
        let avgDuration: String  // formatted string
    }

    /// Multi-instrument enrichment data for user-friendly output
    struct Enrichment: Codable, Sendable {
        let topSymbols: [CPUSymbol]
        let waitState: String
        let allocationDelta: Int64
        let summary: String  // Human-readable enrichment summary
    }

    /// CPU symbol information for user output
    struct CPUSymbol: Codable, Sendable {
        let symbol: String
        let percent: Double
    }
}
