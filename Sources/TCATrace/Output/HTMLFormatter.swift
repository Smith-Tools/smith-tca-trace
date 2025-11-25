import Foundation

/// HTML formatting for interactive visualizations
@available(macOS 14, *)
struct HTMLFormatter: Sendable {
    /// Generate interactive HTML visualization
    static func generateInteractiveHTML(_ analysis: TraceAnalysis) -> String {
        let actionsJSON = try! JSONEncoder().encode(analysis.actions.sorted { $0.timestamp < $1.timestamp })
        let effectsJSON = try! JSONEncoder().encode(analysis.effects.sorted { $0.startTime < $1.startTime })
        let stateChangesJSON = try! JSONEncoder().encode(analysis.sharedStateChanges.sorted { $0.timestamp < $1.timestamp })

        let actionsString = String(data: actionsJSON, encoding: .utf8)!
        let effectsString = String(data: effectsJSON, encoding: .utf8)!
        let stateChangesString = String(data: stateChangesJSON, encoding: .utf8)!

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>TCA Performance Analysis: \(analysis.metadata.name)</title>
            <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    margin: 0;
                    padding: 20px;
                    background: #f5f5f7;
                }
                .container {
                    max-width: 1200px;
                    margin: 0 auto;
                    background: white;
                    border-radius: 12px;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                    overflow: hidden;
                }
                .header {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 30px;
                    text-align: center;
                }
                .header h1 {
                    margin: 0;
                    font-size: 2.5em;
                    font-weight: 600;
                }
                .summary {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                    gap: 20px;
                    padding: 30px;
                    background: #fafafa;
                }
                .metric {
                    background: white;
                    padding: 20px;
                    border-radius: 8px;
                    text-align: center;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                }
                .metric-value {
                    font-size: 2em;
                    font-weight: bold;
                    color: #333;
                }
                .metric-label {
                    color: #666;
                    margin-top: 5px;
                }
                .chart-container {
                    padding: 30px;
                }
                .chart {
                    height: 400px;
                    margin-bottom: 40px;
                }
                .timeline {
                    height: 300px;
                    overflow-x: auto;
                    overflow-y: hidden;
                    border: 1px solid #ddd;
                    border-radius: 8px;
                    position: relative;
                }
                .complexity-\(getComplexityClass(analysis.complexityScore)) {
                    color: \(getComplexityColor(analysis.complexityScore));
                }
                .action-item {
                    position: absolute;
                    height: 20px;
                    border-radius: 4px;
                    background: #667eea;
                    color: white;
                    font-size: 10px;
                    display: flex;
                    align-items: center;
                    padding: 0 5px;
                    cursor: pointer;
                    white-space: nowrap;
                }
                .slow-action {
                    background: #ff6b6b;
                }
                .recommendations {
                    padding: 30px;
                    background: #f8f9fa;
                }
                .recommendations h3 {
                    margin-top: 0;
                    color: #333;
                }
                .recommendation {
                    background: white;
                    padding: 15px;
                    border-left: 4px solid #667eea;
                    margin-bottom: 10px;
                    border-radius: 4px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>TCA Performance Analysis</h1>
                    <p>\(analysis.metadata.name)</p>
                    <div class="metric-value complexity-\(getComplexityClass(analysis.complexityScore))">
                        Score: \(String(format: "%.0f", analysis.complexityScore))/100
                    </div>
                </div>

                <div class="summary">
                    <div class="metric">
                        <div class="metric-value">\(analysis.actions.count)</div>
                        <div class="metric-label">Total Actions</div>
                    </div>
                    <div class="metric">
                        <div class="metric-value">\(analysis.metrics.slowActions)</div>
                        <div class="metric-label">Slow Actions</div>
                    </div>
                    <div class="metric">
                        <div class="metric-value">\(String(format: "%.1f", analysis.metrics.avgDuration * 1000))ms</div>
                        <div class="metric-label">Avg Duration</div>
                    </div>
                    <div class="metric">
                        <div class="metric-value">\(String(format: "%.1f", analysis.duration))s</div>
                        <div class="metric-label">Total Duration</div>
                    </div>
                    <div class="metric">
                        <div class="metric-value">\(analysis.metrics.features.count)</div>
                        <div class="metric-label">Features</div>
                    </div>
                </div>

                <div class="chart-container">
                    <div class="chart">
                        <canvas id="featuresChart"></canvas>
                    </div>
                    <div class="chart">
                        <canvas id="durationChart"></canvas>
                    </div>
                    <div class="chart">
                        <canvas id="complexityGauge"></canvas>
                    </div>
                </div>

                <div class="chart-container">
                    <h3>📊 Timeline View</h3>
                    <div class="timeline" id="timeline"></div>
                </div>

                \(generateRecommendationsHTML(analysis.recommendations))
            </div>

            <script>
                // Data
                const actions = \(actionsString);
                const effects = \(effectsString);
                const stateChanges = \(stateChangesString);
                const analysisData = {
                    totalDuration: \(analysis.duration),
                    features: \(try! JSONEncoder().encode(analysis.metrics.features)),
                    complexityScore: \(analysis.complexityScore)
                };

                // Features Chart
                const featuresCtx = document.getElementById('featuresChart').getContext('2d');
                const featuresData = Object.entries(analysisData.features);
                new Chart(featuresCtx, {
                    type: 'bar',
                    data: {
                        labels: featuresData.map(([name]) => name),
                        datasets: [{
                            label: 'Actions',
                            data: featuresData.map(([, metrics]) => metrics.actionCount),
                            backgroundColor: '#667eea'
                        }, {
                            label: 'Slow Actions',
                            data: featuresData.map(([, metrics]) => metrics.slowActions),
                            backgroundColor: '#ff6b6b'
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            title: {
                                display: true,
                                text: 'Actions by Feature'
                            }
                        }
                    }
                });

                // Duration Chart
                const durationCtx = document.getElementById('durationChart').getContext('2d');
                const slowActions = actions.filter(a => a.duration > 0.016).sort((a, b) => b.duration - a.duration).slice(0, 10);
                new Chart(durationCtx, {
                    type: 'bar',
                    data: {
                        labels: slowActions.map(a => a.fullName),
                        datasets: [{
                            label: 'Duration (ms)',
                            data: slowActions.map(a => a.duration * 1000),
                            backgroundColor: '#ff6b6b'
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            title: {
                                display: true,
                                text: 'Top 10 Slowest Actions'
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

                // Complexity Gauge
                const complexityCtx = document.getElementById('complexityGauge').getContext('2d');
                const complexityScore = analysisData.complexityScore;
                new Chart(complexityCtx, {
                    type: 'doughnut',
                    data: {
                        datasets: [{
                            data: [complexityScore, 100 - complexityScore],
                            backgroundColor: [getComplexityColor(complexityScore), '#e0e0e0'],
                            borderWidth: 0
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        cutout: '70%',
                        plugins: {
                            title: {
                                display: true,
                                text: 'Complexity Score'
                            },
                            legend: {
                                display: false
                            }
                        }
                    }
                });

                // Timeline Visualization
                function renderTimeline() {
                    const timeline = document.getElementById('timeline');
                    const totalDuration = analysisData.totalDuration;
                    const timelineWidth = Math.max(1200, totalDuration * 100); // Scale based on duration

                    timeline.style.width = timelineWidth + 'px';

                    actions.forEach((action, index) => {
                        const left = (action.timestamp / totalDuration) * 100;
                        const width = Math.max((action.duration / totalDuration) * 100, 0.5); // Minimum width for visibility

                        const actionEl = document.createElement('div');
                        actionEl.className = 'action-item' + (action.isSlowFor60FPS ? ' slow-action' : '');
                        actionEl.style.left = left + '%';
                        actionEl.style.width = width + '%';
                        actionEl.style.top = (index % 10) * 25 + 'px';
                        actionEl.textContent = action.actionName;
                        actionEl.title = `\\(action.fullName): \\(String(format: "%.1f", action.durationMS))ms`;

                        timeline.appendChild(actionEl);
                    });
                }

                function getComplexityColor(score) {
                    if (score < 25) return '#28a745';
                    if (score < 50) return '#ffc107';
                    if (score < 75) return '#fd7e14';
                    return '#dc3545';
                }

                // Initialize timeline
                renderTimeline();
            </script>
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