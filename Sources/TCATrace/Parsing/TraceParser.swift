import Foundation

/// Main trace parser that orchestrates the entire parsing process
@available(macOS 14, *)
struct TraceParser: Sendable {
    private let xctraceRunner = XCTraceRunner()
    private let xmlParser = SignpostXMLParser()
    private let extractor = SignpostExtractor()
    private let subsystemFilter: String?

    /// Initialize with optional subsystem filter (e.g., "com.scroll.app", "com.myapp.app")
    /// If not provided, auto-detects from trace or falls back to any subsystem with TCA markers
    init(subsystemFilter: String? = nil) {
        self.subsystemFilter = subsystemFilter
    }

    /// Parse a .trace file and extract TCA data
    func parse(traceURL: URL) async throws -> ParsedTraceData {
        // Verify file exists
        guard FileManager.default.fileExists(atPath: traceURL.path) else {
            throw TCATraceError.fileNotFound(traceURL.path)
        }

        // Get basic trace info
        let traceInfo = try await xctraceRunner.getTraceInfo(at: traceURL)

        // Export trace data using xctrace
        let exportData = try await xctraceRunner.exportTrace(at: traceURL, format: .xml)

        // Parse XML to extract signpost events
        let allSignposts = try xmlParser.parse(data: exportData)

        // Filter for TCA-specific signposts with optional subsystem filter
        let tcaSignposts = xmlParser.filterTCASignposts(allSignposts, subsystemFilter: subsystemFilter)

        if tcaSignposts.isEmpty {
            throw TCATraceError.noTCADataFound(
                message: subsystemFilter.map { "No TCA data found for subsystem: '\($0)'" } ?? "No TCA data found"
            )
        }

        // Extract TCA actions, effects, and state changes
        let actions = extractor.extractActions(from: tcaSignposts)
        let effects = extractor.extractEffects(from: tcaSignposts)
        let sharedStateChanges = extractor.extractSharedStateChanges(from: tcaSignposts)

        return ParsedTraceData(
            traceInfo: traceInfo,
            allSignposts: allSignposts,
            tcaSignposts: tcaSignposts,
            actions: actions,
            effects: effects,
            sharedStateChanges: sharedStateChanges
        )
    }

    /// Quick parse - only actions, for performance analysis
    func parseActions(traceURL: URL) async throws -> [TCAAction] {
        let data = try await xctraceRunner.exportTrace(at: traceURL, format: .xml)
        let signposts = try xmlParser.parse(data: data)
        let tcaSignposts = xmlParser.filterTCASignposts(signposts, subsystemFilter: subsystemFilter)

        if tcaSignposts.isEmpty {
            throw TCATraceError.noTCADataFound(
                message: subsystemFilter.map { "No TCA data found for subsystem: '\($0)'" } ?? "No TCA data found"
            )
        }

        return extractor.extractActions(from: tcaSignposts)
    }

    /// Parse trace with filtering options
    func parse(traceURL: URL, filters: ParseFilters) async throws -> ParsedTraceData {
        var data = try await parse(traceURL: traceURL)

        if let featureName = filters.featureName {
            data.actions = data.actions.filter { $0.featureName == featureName }
            data.effects = data.effects.filter { $0.featureName == featureName }
            data.sharedStateChanges = data.sharedStateChanges.filter { $0.featureName == featureName }
        }

        if let actionName = filters.actionName {
            data.actions = data.actions.filter { $0.actionName.contains(actionName) }
        }

        if filters.minDuration > 0 {
            data.actions = data.actions.filter { $0.duration >= filters.minDuration }
        }

        if filters.slowActionsOnly {
            data.actions = data.actions.filter { $0.isSlowFor60FPS }
        }

        return data
    }
}

/// Data resulting from trace parsing
struct ParsedTraceData: Sendable {
    let traceInfo: TraceInfo
    let allSignposts: [SignpostEvent]
    let tcaSignposts: [SignpostEvent]
    var actions: [TCAAction]
    var effects: [TCAEffect]
    var sharedStateChanges: [SharedStateChange]

    var duration: Double {
        actions.map(\.timestamp).max() ?? 0
    }

    var hasData: Bool {
        !actions.isEmpty || !effects.isEmpty || !sharedStateChanges.isEmpty
    }
}

/// Filters to apply during parsing
struct ParseFilters: Sendable {
    let featureName: String?
    let actionName: String?
    let minDuration: Double
    let slowActionsOnly: Bool

    init(
        featureName: String? = nil,
        actionName: String? = nil,
        minDuration: Double = 0,
        slowActionsOnly: Bool = false
    ) {
        self.featureName = featureName
        self.actionName = actionName
        self.minDuration = minDuration
        self.slowActionsOnly = slowActionsOnly
    }
}