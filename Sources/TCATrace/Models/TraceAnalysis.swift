import Foundation

/// Complete analysis result of a TCA trace
struct TraceAnalysis: Codable, Sendable {
    var metadata: AnalysisMetadata
    let actions: [TCAAction]
    let effects: [TCAEffect]
    let sharedStateChanges: [SharedStateChange]
    let metrics: PerformanceMetrics
    let complexityScore: Double
    let recommendations: [String]
    let duration: Double  // Total trace duration

    init(
        metadata: AnalysisMetadata,
        actions: [TCAAction],
        effects: [TCAEffect] = [],
        sharedStateChanges: [SharedStateChange] = [],
        recommendations: [String] = []
    ) {
        self.metadata = metadata
        self.actions = actions
        self.effects = effects
        self.sharedStateChanges = sharedStateChanges
        self.metrics = PerformanceMetrics(actions: actions)

        // Calculate trace duration from last action
        let lastActionTime = actions.map(\.timestamp).max() ?? 0
        self.duration = lastActionTime

        // Calculate complexity score
        let scorer = ComplexityScorer()
        self.complexityScore = scorer.calculateScore(
            metrics: self.metrics,
            sharedStateChanges: sharedStateChanges.count,
            renderTriggers: effects.filter { $0.name.contains("render") }.count
        )

        // Generate recommendations if not provided
        let computedRecommendations: [String]
        if recommendations.isEmpty {
            let engine = RecommendationEngine()
            let temp = TraceAnalysis(
                metadata: metadata,
                actions: actions,
                effects: effects,
                sharedStateChanges: sharedStateChanges,
                metrics: self.metrics,
                complexityScore: self.complexityScore,
                recommendations: [],
                duration: self.duration
            )
            computedRecommendations = engine.generateRecommendations(for: temp)
        } else {
            computedRecommendations = recommendations
        }
        self.recommendations = computedRecommendations
    }

    // Private initializer for when we have all computed values
    private init(
        metadata: AnalysisMetadata,
        actions: [TCAAction],
        effects: [TCAEffect],
        sharedStateChanges: [SharedStateChange],
        metrics: PerformanceMetrics,
        complexityScore: Double,
        recommendations: [String],
        duration: Double
    ) {
        self.metadata = metadata
        self.actions = actions
        self.effects = effects
        self.sharedStateChanges = sharedStateChanges
        self.metrics = metrics
        self.complexityScore = complexityScore
        self.recommendations = recommendations
        self.duration = duration
    }
}

/// Metadata about the analysis
struct AnalysisMetadata: Codable, Sendable {
    let name: String
    let tracePath: String
    let traceDate: Date?
    let analyzedAt: Date
    var storedAt: Date?
    var tags: [String] = []
    var version: String = "1.0.0"

    init(name: String, tracePath: String, traceDate: Date? = nil) {
        self.name = name
        self.tracePath = tracePath
        self.traceDate = traceDate
        self.analyzedAt = Date()
    }
}

/// Comparison result between two traces
struct ComparisonResult: Codable, Sendable {
    let baseline: AnalysisMetadata
    let current: AnalysisMetadata
    let regressions: [Regression]
    let improvements: [Improvement]
    let complexityChange: Double
    let performanceChange: PerformanceChange

    init(baseline: AnalysisMetadata, current: AnalysisMetadata, regressions: [Regression], improvements: [Improvement], complexityChange: Double) {
        self.baseline = baseline
        self.current = current
        self.regressions = regressions
        self.improvements = improvements
        self.complexityChange = complexityChange
        self.performanceChange = PerformanceChange(
            regressions: regressions,
            improvements: improvements
        )
    }
}

/// Performance regression detected between traces
struct Regression: Codable, Sendable {
    let actionName: String
    let baselineDuration: Double
    let currentDuration: Double
    let percentChange: Double

    var severity: RegressionSeverity {
        switch percentChange {
        case 20..<50: return .minor
        case 50..<100: return .moderate
        case 100..<200: return .major
        default: return .critical
        }
    }

    enum RegressionSeverity: String, Codable, CaseIterable {
        case minor = "⚠️"
        case moderate = "🔶"
        case major = "🔴"
        case critical = "💀"
    }
}

/// Performance improvement detected between traces
struct Improvement: Codable, Sendable {
    let actionName: String
    let baselineDuration: Double
    let currentDuration: Double
    let percentChange: Double

    var significance: ImprovementSignificance {
        switch percentChange {
        case 20..<50: return .minor
        case 50..<80: return .moderate
        default: return .major
        }
    }

    enum ImprovementSignificance: String, Codable, CaseIterable {
        case minor = "✅"
        case moderate = "🟢"
        case major = "🚀"
    }
}

/// Summary of performance changes
struct PerformanceChange: Codable, Sendable {
    let totalRegressions: Int
    let totalImprovements: Int
    let avgRegressionPercent: Double
    let maxRegressionPercent: Double
    let avgImprovementPercent: Double
    let maxImprovementPercent: Double

    init(regressions: [Regression], improvements: [Improvement]) {
        self.totalRegressions = regressions.count
        self.totalImprovements = improvements.count

        if regressions.isEmpty {
            self.avgRegressionPercent = 0
            self.maxRegressionPercent = 0
        } else {
            self.avgRegressionPercent = regressions.map(\.percentChange).reduce(0, +) / Double(regressions.count)
            self.maxRegressionPercent = regressions.map(\.percentChange).max() ?? 0
        }

        if improvements.isEmpty {
            self.avgImprovementPercent = 0
            self.maxImprovementPercent = 0
        } else {
            self.avgImprovementPercent = improvements.map(\.percentChange).reduce(0, +) / Double(improvements.count)
            self.maxImprovementPercent = improvements.map(\.percentChange).max() ?? 0
        }
    }
}
