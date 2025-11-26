import Foundation
import ArgumentParser

/// Output formatting modes for different use cases
enum OutputMode: String, CaseIterable, ExpressibleByArgument {
    case user          // Human-friendly markdown
    case agent         // Full data (use sparingly, large context)
    case compact       // DEFAULT for AI: Token-optimized (30-40% reduction)
}

/// Output format types
enum OutputFormat: String, CaseIterable, ExpressibleByArgument {
    case json
    case markdown
    case html
}

@available(macOS 14, *)
struct OutputFormatter: Sendable {
    static func format(_ analysis: TraceAnalysis, mode: OutputMode, format: OutputFormat, summaryOnly: Bool = false, noSummary: Bool = false) -> String {
        // Handle --summary-only flag (ultra-compact, ~50 tokens)
        if summaryOnly {
            return formatSummaryOnly(analysis)
        }

        // Handle --no-summary flag
        let suppressSummary = noSummary

        switch (mode, format) {
        case (.user, .markdown):
            return MarkdownFormatter.formatUserMarkdown(analysis, suppressSummary: suppressSummary)
        case (.agent, .json):
            return JSONFormatter.formatFullAgentJSON(analysis)
        case (.compact, .json):
            return JSONFormatter.formatCompactAgentJSON(analysis)  // DEFAULT for AI
        case (.user, .html):
            return HTMLFormatter.generateInteractiveHTML(analysis)
        case (.user, .json):
            return JSONFormatter.formatUserJSON(analysis)
        case (.agent, .markdown):
            return MarkdownFormatter.formatAgentMarkdown(analysis, suppressSummary: suppressSummary)
        case (.compact, .markdown):
            return MarkdownFormatter.formatCompactMarkdown(analysis)
        default:
            return formatDefault(analysis, mode: mode, format: format, suppressSummary: suppressSummary)
        }
    }

    /// Ultra-compact summary-only format (~50 tokens)
    private static func formatSummaryOnly(_ analysis: TraceAnalysis) -> String {
        let worstAction = analysis.actions.max { $0.duration < $1.duration }
        let worstEffect = analysis.effects.max { $0.duration < $1.duration }
        let longEffectsCount = analysis.effects.filter { $0.isLongRunning }.count

        let summary: [String: Any] = [
            "app": analysis.metadata.name,
            "complexity": Int(analysis.complexityScore),
            "totalActions": analysis.actions.count,
            "slowActions": analysis.metrics.slowActions,
            "longEffects": longEffectsCount,
            "duration": Double(Int(analysis.duration * 10)) / 10,
            "worstAction": worstAction.map { [
                "feature": $0.featureName,
                "action": $0.actionName,
                "duration": Double(Int($0.duration * 1000))
            ] } as Any,
            "worstEffect": worstEffect.map { [
                "name": $0.name,
                "duration": Double(Int($0.duration * 1000))
            ] } as Any
        ]

        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        let data = try! JSONSerialization.data(withJSONObject: summary, options: [])
        return String(data: data, encoding: .utf8)!
    }

    static func format(_ comparison: ComparisonResult, mode: OutputMode, format: OutputFormat) -> String {
        switch (mode, format) {
        case (.user, .markdown):
            return MarkdownFormatter.formatComparisonMarkdown(comparison)
        case (.agent, .json), (.compact, .json):
            return JSONFormatter.formatComparisonJSON(comparison)
        default:
            // Fallback: use markdown when HTML view is not available
            return MarkdownFormatter.formatComparisonMarkdown(comparison)
        }
    }

    private static func formatDefault(_ analysis: TraceAnalysis, mode: OutputMode, format: OutputFormat, suppressSummary: Bool = false) -> String {
        switch format {
        case .json:
            return JSONFormatter.formatCompactAgentJSON(analysis)
        case .markdown:
            return MarkdownFormatter.formatUserMarkdown(analysis, suppressSummary: suppressSummary)
        case .html:
            return HTMLFormatter.generateInteractiveHTML(analysis)
        }
    }

    private static func formatComparisonDefault(_ comparison: ComparisonResult, mode: OutputMode, format: OutputFormat) -> String {
        switch format {
        case .json:
            return JSONFormatter.formatComparisonJSON(comparison)
        case .markdown, .html:
            return MarkdownFormatter.formatComparisonMarkdown(comparison)
        }
    }
}

/// Token optimization utilities
private struct TokenOptimizer {
    /// Round to specified decimal places to reduce token usage
    static func roundToDecimal(_ value: Double, places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (value * multiplier).rounded() / multiplier
    }

    /// Truncate string to reduce token usage while preserving meaning
    static func truncateString(_ string: String, maxLength: Int) -> String {
        if string.count <= maxLength {
            return string
        }
        return String(string.prefix(maxLength - 3)) + "..."
    }

    /// Create abbreviated version of feature.action name
    static func abbreviateActionName(_ fullName: String) -> String {
        let parts = fullName.components(separatedBy: ".")
        if parts.count >= 2 {
            let feature = String(parts[0].prefix(3))
            let action = String(parts[1].prefix(8))
            return "\(feature).\(action)"
        }
        return String(fullName.prefix(12))
    }
}
