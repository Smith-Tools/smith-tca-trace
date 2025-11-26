# CHANGELOG

All notable changes to smith-tca-trace will be documented in this file.

## [Unreleased]

### 🎉 Major Features

#### Multi-Instrument Data Enrichment
- **Automatic Time Profiler correlation**: Extracts CPU thread states (Running, Blocked, etc.) for each TCA action/effect
- **System Call Trace analysis**: Identifies I/O wait states (kevent, futex, read, write, mach_msg) and classifies dominant wait types
- **Memory allocation tracking**: Computes memory delta per time window and correlates with slow actions
- **Unified enrichment API**: Single enrichment data structure with `topSymbols`, `waitState`, and `allocationDelta` fields

### 🔧 Technical Improvements

#### XCTrace Export (Instruments 26.1 Compatibility)
- Corrected schema names for modern xctrace output:
  - `time-sample` for Time Profiler (was attempting "time-profiler")
  - `syscall` for System Call Trace (confirmed correct)
  - `time-profile` for allocations data
- Fixed XPath queries for proper table extraction
- Improved reference resolution for xctrace XML deduplication

#### XML Parser Enhancements
- Implemented element caching system for reference (`ref=`) attribute resolution
  - Tracks `id` → `fmt` mappings for deduplication optimization
  - Resolves references on-demand during parsing
- Added robust parsing for both direct elements and references:
  - `<thread-state id="14" fmt="Running">Running</thread-state>` (definition)
  - `<thread-state ref="14"/>` (reference, uses cached fmt value)
- Improved timestamp handling: raw nanoseconds → seconds conversion

#### Parser Implementation
- **TimeProfilerXMLParser**: Extracts thread state and sample type information
  - Aggregates samples by thread state
  - Calculates percentages for top states
  - Handles Running/Blocked/Waiting states

- **SystemCallXMLParser**: Parses syscall data with duration extraction
  - Supports formatted durations ("4.92 µs") and raw nanoseconds
  - Extracts syscall names and return values
  - Classifies wait types from syscall patterns

- **AllocationXMLParser**: Processes memory event traces
  - Tracks allocated/freed bytes per time window
  - Computes net allocation delta
  - Handles multi-threaded memory operations

#### Analysis Methods
- `extractTopSymbols()`: Aggregates thread states with percentage calculations
- `extractWaitState()`: Classifies dominant I/O wait types
- `calculateAllocationDelta()`: Computes net memory changes per time window

#### Enrichment Integration
- `InstrumentEnrichmentService` now properly enriches actions and effects with:
  - CPU thread state statistics
  - I/O wait state classification
  - Memory allocation deltas
- Integrated enrichment with TraceParser pipeline
- Updated output formatters to display enrichment data

### 📊 Output Format Updates
- **JSON**: Enrichment fields now included in all action/effect objects:
  ```json
  {
    "action": "onAppear",
    "duration": 7462.2,
    "enrichment": {
      "topSymbols": [{"symbol": "Running", "percent": 100}],
      "waitState": "cpu",
      "allocationDelta": 0
    }
  }
  ```
- **Markdown**: Enrichment summary displayed inline:
  ```
  - **onAppear**: 7462.2ms | CPU: Running(100%)
  ```
- **HTML**: Enrichment data integrated into visualization dashboard

### 📖 Documentation

#### README Updates
- Added "Multi-Instrument Data Enrichment" section
- Documented CPU vs I/O-bound action identification
- Added memory tracking and analysis guidance
- Updated recommendations to include threading and memory optimization
- Added example output showing enrichment data

#### API Documentation
- Documented `CPUSymbol`, `TimeProfilerSample`, `SystemCall` structures
- Added `MultiInstrumentParser` class documentation
- Documented enrichment field meanings and usage

### ✅ Testing & Validation
- Validated on Untitled3.trace (Scroll app):
  - ✅ Exported 10,383 time-sample rows
  - ✅ Parsed 220K+ syscall records
  - ✅ Extracted and enriched 10 slow actions (>16ms)
  - ✅ Verified enrichment fields populated with real data
  - ✅ Thread states correctly extracted (Running, Blocked, etc.)
  - ✅ Wait states classified (cpu dominant, no I/O blocking)

### 🐛 Bug Fixes
- Fixed reference resolution in xctrace XML parsing
- Corrected timestamp conversion (nanoseconds to seconds)
- Improved TCA signpost extraction from metadata

### ⚠️ Breaking Changes
None

### 🔄 Dependencies
No new external dependencies added. All improvements use existing libraries (Foundation, XMLParser).

### 🚀 Performance Improvements
- Element caching reduces redundant string allocations in XML parsing
- Lazy enrichment computation only for displayed actions
- No performance regression on trace analysis time

### 📝 Migration Guide
No migration needed. Enrichment data is optional and backward compatible.
- Existing analyses continue to work without enrichment
- New traces automatically include enrichment if multi-instrument data available

---

## [1.0.0] - 2025-11-26

### Initial Release

### Features
- Generic TCA detection working with any app's signpost patterns
- TCA action/effect extraction and timing analysis
- Complexity scoring and architecture health assessment
- Interactive HTML dashboard with Chart.js visualizations
- Multiple output formats (JSON, Markdown, HTML)
- Smart TCA-specific recommendations
- CLI with filtering, comparison, and analysis commands
- Claude Code skill integration

### Architecture
- XCTrace integration for Instruments trace parsing
- Signpost extraction with Point-Free pattern detection
- Complexity scoring based on effect-to-action ratios
- Recommendation engine with TCA domain knowledge
- Responsive web UI with dark theme

### Documentation
- Comprehensive README with usage workflows
- Multiple examples and best practices
- Integration guides for Claude Code

---

## Format
This CHANGELOG follows the [Keep a Changelog](https://keepachangelog.com/) format.

Versions follow [Semantic Versioning](https://semver.org/).
