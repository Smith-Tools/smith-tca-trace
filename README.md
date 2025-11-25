# 🚀 smith-tca-trace

**TCA performance profiling and analysis tool** - The Composable Architecture performance profiler for Apple Instruments traces.

## 📋 Overview

`smith-tca-trace` is a command-line tool that analyzes The Composable Architecture (TCA) applications using Instruments traces to identify performance bottlenecks, complexity issues, and provide actionable recommendations. It extracts TCA-specific signposts and generates comprehensive performance reports.

### ✨ Key Features

- **🔍 Generic TCA Detection**: Works with any TCA app using Point-Free's signpost instrumentation patterns
- **📊 Interactive Visualizations**: Modern web dashboard with Chart.js visualizations
- **🏗️ TCA-Focused Insights**: State mutations, actions, side effects, and dependencies analysis
- **⚡ Performance Metrics**: Action distribution, effect-to-action ratios, complexity scoring
- **🎯 Smart Recommendations**: TCA-specific optimization advice (@Dependency, debouncing, caching)
- **📱 Responsive Design**: Mobile-friendly interface for tablet debugging
- **🌊 Modern Dashboard**: Dark theme with glassmorphism effects and rich infographics

## 🛠️ Installation

### Prerequisites

- **macOS 14+** (for Instruments integration)
- **Xcode** (for xctrace tool)
- **Swift 5.9+**

### Build from Source

```bash
git clone <repository-url>
cd smith-tca-trace
swift build -c release
```

## 🚀 Quick Start

### Basic Usage

```bash
# Analyze a trace file
smith-tca-trace analyze /path/to/trace.trace

# Generate interactive HTML visualization
smith-tca-trace visualize /path/to/trace.trace --output report.html

# Compare two traces
smith-tca-trace compare before.trace after.trace

# List available traces
smith-tca-trace list
```

### Example Workflow

```bash
# 1. Record Instruments trace with TCA signposts
xctrace record --template "Time Profiler" --launch appname.app

# 2. Analyze performance
smith-tca-trace analyze ~/Library/Developer/Xcode/DerivedData/appname/Build/Products/Debug/appname.app/trace.trace

# 3. Generate interactive dashboard
smith-tca-trace visualize trace.trace --output performance-report.html

# 4. Open in browser
open performance-report.html
```

## 📊 Output Formats

### Interactive HTML Dashboard (Default)

- **TCA Core Principles Analysis**: State mutations, actions, side effects, dependencies
- **Effect Duration Comparison**: Visual chart showing effect performance
- **Action Distribution**: Doughnut chart of TCA action types
- **Timeline Analysis**: Scatter plot of action density over time
- **Performance Metrics**: Effect-to-action ratios, complexity scoring
- **TCA-Specific Recommendations**: Actionable optimization advice

### Other Formats

- **JSON** (`--mode agent`): Complete structured data for automation
- **Markdown** (`--format markdown`): Human-readable reports
- **Compact JSON**: Optimized for AI agents (30-40% token reduction)

## 🎯 TCA Insights

### State Analysis
- **State Mutations**: Track and categorize state changes
- **Effect Monitoring**: Identify long-running and heavy effects
- **Dependency Analysis**: Effect-to-action ratios and patterns

### Performance Metrics
- **Action Distribution**: UI Events, Data Loading, State Mutations, Navigation
- **Effect Performance**: Duration comparison and bottleneck identification
- **Complexity Scoring**: Architecture health assessment
- **Frame Budget**: Animation and UI responsiveness analysis

### Recommendations
- **@Dependency Usage**: Heavy effect optimization suggestions
- **Debouncing**: Frequent state change optimization
- **Caching**: Data loading and computation optimization
- **Cancellation**: Proper effect lifecycle management

## 🔧 Commands

### `analyze`
Analyze trace and generate performance report
```bash
smith-tca-trace analyze <trace-file> [options]
  --mode <user|agent>       Output format
  --format <json|html|md>   Output format
  --output <file>          Output file path
  --no-recommendations     Skip recommendations
```

### `visualize`
Generate interactive HTML dashboard
```bash
smith-tca-trace visualize <trace-file> --output <report.html>
```

### `compare`
Compare two traces side-by-side
```bash
smith-tca-trace compare <before-trace> <after-trace> --output comparison.html
```

### `list`
List available traces
```bash
smith-tca-trace list [--recent] [--count <number>]
```

### `stats`
Show trace statistics
```bash
smith-tca-trace stats <trace-file>
```

## 🏗️ Architecture

### Core Components

- **SignpostExtractor**: Extract TCA signposts from Instruments traces
- **TraceParser**: Parse and validate trace data
- **ComplexityScorer**: Calculate architecture complexity metrics
- **RecommendationEngine**: Generate TCA-specific optimization advice
- **HTMLFormatter**: Create interactive web visualizations

### Generic TCA Detection

The tool uses pattern-based detection to work with any TCA application:

```swift
// Extract action names from signpost patterns
let bracketPattern = #"\[([^\]]+)\].*?(\w+Feature)\.Action\.([\w.()]+)"#
let effectPattern = #"(?:Output from|Started from)\s+.*?(\w+Feature)\.Action\.([\w.()]+)"#
```

### UI Technology Stack

- **Svelte**: Reactive component framework
- **Chart.js**: Advanced data visualization
- **Vite**: Fast build tool
- **CSS Grid/Flexbox**: Modern responsive layouts

## 📈 Performance Features

### Action Classification
- **UI Events**: User interactions (tapped, selected, changed)
- **Data Loading**: Effects, fetch operations, background tasks
- **State Mutations**: Direct state updates and changes
- **Navigation**: Route and view management actions

### Effect Analysis
- **Duration Tracking**: Microsecond precision timing
- **Long-Running Detection**: >500ms threshold alerts
- **Performance Bottlenecks**: Critical effect identification
- **Cancellation Issues**: Missing .cancellable() detection

### Architecture Insights
- **Effect-to-Action Ratio**: Balance assessment
- **Complexity Scoring**: 0-100 health metric
- **State Change Patterns**: Shared state tracking
- **Dependency Analysis**: @Dependency optimization opportunities

## 🎨 Dashboard Features

### Visual Elements
- **Dark Theme**: Optimized for long debugging sessions
- **Glassmorphism**: Modern blur and transparency effects
- **Color Coding**: Performance severity indicators
- **Interactive Charts**: Hover effects and tooltips

### Responsive Design
- **Mobile Friendly**: Works on tablets during development
- **Touch Optimized**: Mobile interaction patterns
- **Adaptive Layout**: Flexible grid system

### Data Visualization
- **Doughnut Charts**: Action distribution breakdown
- **Scatter Plots**: Timeline density analysis
- **Bar Charts**: Effect duration comparison
- **Progress Metrics**: Real-time performance indicators

## 🔄 Workflow Integration

### Development
```bash
# Integrate into CI/CD
smith-tca-trace analyze build.trace --mode agent --output metrics.json

# Performance regression testing
smith-tca-trace compare baseline.trace current.trace --threshold 0.1
```

### Monitoring
```bash
# Continuous performance monitoring
smith-tca-trace stats production.trace --format json | jq '.complexityScore'

# Automated reporting
smith-tca-trace visualize daily.trace --output reports/daily-$(date +%Y%m%d).html
```

## 🐛 Troubleshooting

### Common Issues

**No TCA signposts found:**
- Ensure TCA application has signpost instrumentation
- Check that signposts follow Point-Free's naming conventions
- Verify trace contains `[FeatureName] Feature.Action.actionName` patterns

**Empty visualization:**
- Check trace file path and permissions
- Ensure trace was recorded with Time Profiler template
- Verify xctrace tool is accessible

**Performance issues:**
- Large traces (>1GB) may require additional processing time
- Use `--no-recommendations` for faster analysis
- Consider filtering specific time ranges

### Debug Mode

```bash
# Enable verbose logging
RUST_LOG=debug smith-tca-trace analyze trace.trace

# Check trace contents
smith-tca-trace list --details trace.trace
```

## 📚 Examples

### Real-World Analysis

```bash
# Reading Library TCA App Analysis
smith-tca-trace visualize ReadingLibrary.trace \
  --output reading-library-perf.html

# Results:
# - 107 total actions, 17 effects
# - Critical bottleneck: inspector(.loadData) - 3298ms
# - Effect-to-action ratio: 33.6% (healthy)
# - Health score: 87/100 (good architecture)
# - Recommendation: Implement caching for heavy effects
```

### Performance Regression

```bash
# Compare before/after optimization
smith-tca-trace compare before-optimization.trace after-optimization.trace \
  --output optimization-results.html

# Typical improvements:
# - Effect duration reduced by 60%
# - Complexity score improved from 45 to 32
# - Effect-to-action ratio optimized to 28%
```

## 🔮 Future Roadmap

### Planned Features
- [ ] Real-time monitoring integration
- [ ] Performance alerting system
- [ ] Baseline management
- [ ] Team sharing and collaboration
- [ ] Integration with CI/CD pipelines

### Technical Improvements
- [ ] Swift Package Manager distribution
- [ ] macOS app wrapper
- [ ] Plug-in architecture for custom analyzers
- [ ] Export to additional formats (CSV, PDF)

## 🤝 Contributing

### Development Setup
```bash
git clone <repository-url>
cd smith-tca-trace
swift build
swift test
```

### Code Style
- Follow Swift API Design Guidelines
- Use comprehensive unit tests
- Document all public APIs
- Ensure cross-platform compatibility

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Point-Free**: TCA signpost instrumentation patterns
- **Apple Instruments**: Trace data extraction capabilities
- **Swift ArgumentParser**: CLI framework
- **Svelte**: Reactive UI framework
- **Chart.js**: Data visualization library

---

## 📞 Support

For issues, feature requests, or questions:
- Create an issue in the GitHub repository
- Check the troubleshooting section above
- Review the examples and documentation

**Built with ❤️ for The Composable Architecture community**