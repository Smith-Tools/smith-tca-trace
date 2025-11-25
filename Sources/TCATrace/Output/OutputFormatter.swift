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
    static func format(_ analysis: TraceAnalysis, mode: OutputMode, format: OutputFormat) -> String {
        switch (mode, format) {
        case (.user, .markdown):
            return MarkdownFormatter.formatUserMarkdown(analysis)
        case (.agent, .json):
            return JSONFormatter.formatFullAgentJSON(analysis)
        case (.compact, .json):
            return JSONFormatter.formatCompactAgentJSON(analysis)  // DEFAULT for AI
        case (.user, .html):
            return HTMLFormatter.generateInteractiveHTML(analysis)
        case (.user, .json):
            return JSONFormatter.formatUserJSON(analysis)
        case (.agent, .markdown):
            return MarkdownFormatter.formatAgentMarkdown(analysis)
        case (.compact, .markdown):
            return MarkdownFormatter.formatCompactMarkdown(analysis)
        default:
            return formatDefault(analysis, mode: mode, format: format)
        }
    }

    static func format(_ comparison: ComparisonResult, mode: OutputMode, format: OutputFormat) -> String {
        switch (mode, format) {
        case (.user, .markdown):
            return MarkdownFormatter.formatComparisonMarkdown(comparison)
        case (.agent, .json), (.compact, .json):
            return JSONFormatter.formatComparisonJSON(comparison)
        default:
            return formatComparisonDefault(comparison, mode: mode, format: format)
        }
    }

    private static func formatDefault(_ analysis: TraceAnalysis, mode: OutputMode, format: OutputFormat) -> String {
        switch format {
        case .json:
            return JSONFormatter.formatCompactAgentJSON(analysis)
        case .markdown:
            return MarkdownFormatter.formatUserMarkdown(analysis)
        case .html:
            return HTMLFormatter.generateInteractiveHTML(analysis)
        }
    }

    private static func formatComparisonDefault(_ comparison: ComparisonResult, mode: OutputMode, format: OutputFormat) -> String {
        switch format {
        case .json:
            return JSONFormatter.formatComparisonJSON(comparison)
        case .markdown:
            return MarkdownFormatter.formatComparisonMarkdown(comparison)
        case .html:
            return HTMLFormatter.generateComparisonHTML(comparison)
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