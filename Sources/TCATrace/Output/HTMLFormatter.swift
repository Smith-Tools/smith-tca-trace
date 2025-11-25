import Foundation

/// HTML formatting for interactive visualizations
@available(macOS 14, *)
struct HTMLFormatter: Sendable {
    /// Generate interactive HTML visualization
    static func generateInteractiveHTML(_ analysis: TraceAnalysis) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let analysisJSON = String(data: try! encoder.encode(analysis), encoding: .utf8) ?? "{}"

        // Try to inline built Svelte bundle; otherwise fall back to legacy static layout.
        let css = loadResource(name: "bundle", ext: "css")
        let js = loadResource(name: "bundle", ext: "js")

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>TCA Performance Analysis: \(analysis.metadata.name)</title>
            \(css.map { "<style>\($0)</style>" } ?? "")
        </head>
        <body>
            <div id="app"></div>
            <script>window.__TCA_ANALYSIS__ = \(analysisJSON);</script>
            \(js.map { "<script>\($0)</script>" } ?? "<p style='padding:16px;font-family:system-ui'>UI bundle missing. Rebuild UI (npm install; npm run build; npm run copy-ui) then rerun.</p>")
        </body>
        </html>
        """
    }

    /// Generate comparison HTML
    static func generateComparisonHTML(_ comparison: ComparisonResult) -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>TCA Performance Comparison</title>
            <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 20px; background: #f5f5f7; }
                .container { max-width: 1000px; margin: 0 auto; background: white; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                .header { background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%); color: white; padding: 30px; text-align: center; }
                .comparison-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 30px; padding: 30px; }
                .trace-info { background: #f8f9fa; padding: 20px; border-radius: 8px; }
                .changes { padding: 30px; }
                .regression { background: #ffe6e6; padding: 15px; border-left: 4px solid #dc3545; margin-bottom: 10px; }
                .improvement { background: #e6f7e6; padding: 15px; border-left: 4px solid #28a745; margin-bottom: 10px; }
                .chart { height: 400px; margin: 20px 0; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>TCA Performance Comparison</h1>
                    <p>\(comparison.baseline.name) vs \(comparison.current.name)</p>
                </div>

                <div class="comparison-grid">
                    <div class="trace-info">
                        <h3>🔵 Baseline</h3>
                        <p><strong>Name:</strong> \(comparison.baseline.name)</p>
                        <p><strong>Analyzed:</strong> \(ISO8601DateFormatter().string(from: comparison.baseline.analyzedAt))</p>
                    </div>
                    <div class="trace-info">
                        <h3>🟡 Current</h3>
                        <p><strong>Name:</strong> \(comparison.current.name)</p>
                        <p><strong>Analyzed:</strong> \(ISO8601DateFormatter().string(from: comparison.current.analyzedAt))</p>
                    </div>
                </div>

                <div class="changes">
                    <h2>📊 Summary</h2>
                    <p><strong>Complexity Change:</strong> \(String(format: "%+.1f", comparison.complexityChange))</p>
                    <p><strong>Regressions:</strong> \(comparison.regressions.count)</p>
                    <p><strong>Improvements:</strong> \(comparison.improvements.count)</p>

                    <div class="chart">
                        <canvas id="comparisonChart"></canvas>
                    </div>

                    \(generateChangesHTML(comparison))
                </div>
            </div>

            <script>
                const comparisonData = {
                    regressions: \(try! JSONEncoder().encode(comparison.regressions)),
                    improvements: \(try! JSONEncoder().encode(comparison.improvements))
                };

                const ctx = document.getElementById('comparisonChart').getContext('2d');
                new Chart(ctx, {
                    type: 'bar',
                    data: {
                        labels: comparisonData.regressions.map(r => r.actionName).slice(0, 5),
                        datasets: [{
                            label: 'Baseline (ms)',
                            data: comparisonData.regressions.map(r => r.baselineDuration * 1000).slice(0, 5),
                            backgroundColor: '#6c757d'
                        }, {
                            label: 'Current (ms)',
                            data: comparisonData.regressions.map(r => r.currentDuration * 1000).slice(0, 5),
                            backgroundColor: '#dc3545'
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            title: {
                                display: true,
                                text: 'Top Regressions'
                            }
                        },
                        scales: {
                            y: {
                                beginAtZero: true,
                                title: {
                                    display: true,
                                    text: 'Duration (ms)'
                                }
                            }
                        }
                    }
                });
            </script>
        </body>
        </html>
        """
    }

    private static func getComplexityClass(_ score: Double) -> String {
        switch score {
        case 0..<25: return "excellent"
        case 25..<50: return "good"
        case 50..<75: return "fair"
        default: return "poor"
        }
    }

    private static func getComplexityColor(_ score: Double) -> String {
        switch score {
        case 0..<25: return "#28a745"
        case 25..<50: return "#ffc107"
        case 50..<75: return "#fd7e14"
        default: return "#dc3545"
        }
    }

    /// Load resource from SPM resources (UI bundle)
    private static func loadResource(name: String, ext: String) -> String? {
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "UI/dist") ??
            Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "dist") {
            return try? String(contentsOf: url)
        }
        #endif
        return nil
    }

    private static func generateRecommendationsHTML(_ recommendations: [String]) -> String {
        guard !recommendations.isEmpty else { return "" }

        var html = """
        <div class="recommendations">
            <h3>🎯 Recommendations</h3>
        """

        for recommendation in recommendations {
            html += """
            <div class="recommendation">
                \(recommendation)
            </div>
            """
        }

        html += "</div>"
        return html
    }

    private static func generateChangesHTML(_ comparison: ComparisonResult) -> String {
        var html = ""

        if !comparison.regressions.isEmpty {
            html += "<h3>🔴 Regressions</h3>"
            for regression in comparison.regressions.prefix(10) {
                html += """
                <div class="regression">
                    <strong>\(regression.actionName)</strong>:
                    \(String(format: "%.1f", regression.baselineDuration * 1000))ms →
                    \(String(format: "%.1f", regression.currentDuration * 1000))ms
                    (\(String(format: "+%.0f", regression.percentChange))%) \(regression.severity.rawValue)
                </div>
                """
            }
        }

        if !comparison.improvements.isEmpty {
            html += "<h3>✅ Improvements</h3>"
            for improvement in comparison.improvements.prefix(10) {
                html += """
                <div class="improvement">
                    <strong>\(improvement.actionName)</strong>:
                    \(String(format: "%.1f", improvement.baselineDuration * 1000))ms →
                    \(String(format: "%.1f", improvement.currentDuration * 1000))ms
                    (\(String(format: "-%.0f", improvement.percentChange))%) \(improvement.significance.rawValue)
                </div>
                """
            }
        }

        return html
    }
}
