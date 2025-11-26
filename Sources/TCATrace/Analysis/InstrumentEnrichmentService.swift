import Foundation

/// Service that enriches TCA actions and effects with multi-instrument data
@available(macOS 14, *)
struct InstrumentEnrichmentService: Sendable {

    /// Enrich actions and effects with profiler, syscall, and allocation data
    static func enrich(
        actions: inout [TCAAction],
        effects: inout [TCAEffect],
        profilerData: Data?,
        syscallData: Data?,
        allocationData: Data?
    ) {
        // Parse multi-instrument data
        let profilerSamples = profilerData.map { MultiInstrumentParser.parseTimeProfiler($0) } ?? []
        let syscalls = syscallData.map { MultiInstrumentParser.parseSystemCalls($0) } ?? []
        let allocations = allocationData.map { MultiInstrumentParser.parseAllocations($0) } ?? []

        // Enrich actions
        for i in actions.indices {
            var action = actions[i]
            if action.isSlowFor60FPS {
                let timeWindow = (action.timestamp, action.timestamp + action.duration)

                action.topSymbols = extractCPUSymbols(
                    from: MultiInstrumentParser.extractTopSymbols(from: profilerSamples, in: timeWindow)
                )

                action.waitState = MultiInstrumentParser.extractWaitState(
                    from: syscalls, in: timeWindow
                )

                action.allocationDelta = MultiInstrumentParser.calculateAllocationDelta(
                    from: allocations, in: timeWindow
                )
                      }
            actions[i] = action
        }

        // Enrich effects
        for i in effects.indices {
            var effect = effects[i]
            if effect.isLongRunning {
                let timeWindow = (effect.startTime, effect.endTime)

                effect.topSymbols = extractCPUSymbols(
                    from: MultiInstrumentParser.extractTopSymbols(from: profilerSamples, in: timeWindow)
                )

                effect.waitState = MultiInstrumentParser.extractWaitState(
                    from: syscalls, in: timeWindow
                )

                effect.allocationDelta = MultiInstrumentParser.calculateAllocationDelta(
                    from: allocations, in: timeWindow
                )
            }
            effects[i] = effect
        }
    }

    /// Extract CPU symbols from parser results and convert to CPUSymbol model
    private static func extractCPUSymbols(
        from symbols: [MultiInstrumentParser.CallstackSymbol]
    ) -> [CPUSymbol] {
        return symbols.map { symbol in
            CPUSymbol(
                symbolName: symbol.symbolName,
                moduleName: symbol.moduleName,
                percent: symbol.percent
            )
        }
    }

    /// Get enrichment summary statistics
    static func getEnrichmentStats(
        actions: [TCAAction],
        effects: [TCAEffect]
    ) -> EnrichmentStats {
        let enrichedActions = actions.filter { $0.hasEnrichment }
        let enrichedEffects = effects.filter { $0.hasEnrichment }

        return EnrichmentStats(
            totalActions: actions.count,
            enrichedActions: enrichedActions.count,
            totalEffects: effects.count,
            enrichedEffects: enrichedEffects.count,
            topWaitStates: extractTopWaitStates(from: enrichedActions + enrichedEffects),
            topCPUIntensiveFeatures: extractTopCPUIntensiveFeatures(from: enrichedActions + enrichedEffects)
        )
    }

    private static func extractTopWaitStates(from items: [any EnrichedItem]) -> [(String, Int)] {
        let waitStates = items.compactMap { item -> String? in
            let waitState = item.waitState
            return waitState.isEmpty || waitState == "cpu" ? nil : waitState
        }

        return Dictionary(grouping: waitStates, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { ($0.key, $0.value) }
    }

    private static func extractTopCPUIntensiveFeatures(from items: [any EnrichedItem]) -> [(String, Double)] {
        let featureCPU = Dictionary(grouping: items, by: { "\($0.featureName)" })
            .mapValues { items in
                items.compactMap { $0.topSymbols.first?.percent }
                    .reduce(0, +)
            }

        return featureCPU.sorted { $0.value > $1.value }
            .prefix(5)
            .map { ($0.key, $0.value) }
    }
}

/// Protocol for items that can be enriched with instrument data
private protocol EnrichedItem {
    var featureName: String { get }
    var topSymbols: [CPUSymbol] { get }
    var waitState: String { get }
}

extension TCAAction: EnrichedItem {}
extension TCAEffect: EnrichedItem {}

/// Statistics about enrichment results
struct EnrichmentStats: Sendable {
    let totalActions: Int
    let enrichedActions: Int
    let totalEffects: Int
    let enrichedEffects: Int
    let topWaitStates: [(String, Int)]
    let topCPUIntensiveFeatures: [(String, Double)]

    var actionEnrichmentRate: Double {
        guard totalActions > 0 else { return 0 }
        return Double(enrichedActions) / Double(totalActions) * 100
    }

    var effectEnrichmentRate: Double {
        guard totalEffects > 0 else { return 0 }
        return Double(enrichedEffects) / Double(totalEffects) * 100
    }

    var summary: String {
        return """
        Enrichment Summary:
        - Actions: \(enrichedActions)/\(totalActions) enriched (\(String(format: "%.1f", actionEnrichmentRate))%)
        - Effects: \(enrichedEffects)/\(totalEffects) enriched (\(String(format: "%.1f", effectEnrichmentRate))%)
        - Top wait states: \(topWaitStates.map { "\($0.0) (\($0.1))" }.joined(separator: ", "))
        - Top CPU features: \(topCPUIntensiveFeatures.map { "\($0.0) (\(String(format: "%.1f", $0.1))%)" }.joined(separator: ", "))
        """
    }
}