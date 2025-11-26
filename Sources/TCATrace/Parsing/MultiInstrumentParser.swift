import Foundation

/// Robust parsers for multi-instrument data from Instruments 26.1 using XMLParser
@available(macOS 14, *)
struct MultiInstrumentParser {

    // MARK: - Time Profiler Data

    struct TimeProfilerSample {
        let timestamp: TimeInterval
        let threadId: UInt64
        let threadState: String
        let callstackRef: String?
        let sampleType: String
        let coreIndex: Int?
        let weight: Double
    }

    struct CallstackSymbol {
        let address: UInt64
        let symbolName: String
        let moduleName: String?
        let imageName: String?
        let percent: Double
    }

    /// XMLParser delegate for time profiler data
    class TimeProfilerXMLParser: NSObject, XMLParserDelegate {
        private var samples: [TimeProfilerSample] = []
        private var currentSample: [String: String] = [:]
        private var currentElement = ""
        private var inSampleRow = false
        private var elementContent = ""
        // Cache fmt values by id for reference resolution
        private var elementCache: [String: String] = [:]

        func parse(data: Data) -> [TimeProfilerSample] {
            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
            return samples
        }

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
            currentElement = elementName
            elementContent = ""

            switch elementName {
            case "row":
                inSampleRow = true
                currentSample.removeAll()
            case "sample-time":
                if let fmt = attributeDict["fmt"] {
                    currentSample["timestamp"] = fmt
                    // Cache for reference
                    if let id = attributeDict["id"] {
                        elementCache[id] = fmt
                    }
                } else if let ref = attributeDict["ref"], let cached = elementCache[ref] {
                    currentSample["timestamp"] = cached
                }
            case "thread":
                if let fmt = attributeDict["fmt"] {
                    // Extract thread ID from format like "Main Thread 0x53996c (Scroll, pid: 30463)"
                    if let hexMatch = fmt.range(of: "0x[0-9a-f]+", options: .regularExpression) {
                        currentSample["threadId"] = String(fmt[hexMatch])
                    }
                }
            case "thread-state":
                if let fmt = attributeDict["fmt"] {
                    currentSample["threadState"] = fmt
                    if let id = attributeDict["id"] {
                        elementCache[id] = fmt
                    }
                } else if let ref = attributeDict["ref"], let cached = elementCache[ref] {
                    currentSample["threadState"] = cached
                }
            case "time-sample-kind":
                if let fmt = attributeDict["fmt"] {
                    currentSample["sampleType"] = fmt
                    if let id = attributeDict["id"] {
                        elementCache[id] = fmt
                    }
                } else if let ref = attributeDict["ref"], let cached = elementCache[ref] {
                    currentSample["sampleType"] = cached
                }
            case "core":
                if let fmt = attributeDict["fmt"], fmt.hasPrefix("CPU ") {
                    let coreStr = String(fmt.dropFirst(4))
                    // Extract just the number
                    if let coreNum = coreStr.components(separatedBy: " ").first {
                        currentSample["coreIndex"] = coreNum
                    }
                }
            case "kperf-bt":
                if let ref = attributeDict["ref"] {
                    currentSample["callstackRef"] = ref
                }
            default:
                break
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            if !inSampleRow { return }

            let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedString.isEmpty { return }

            elementContent += trimmedString

            switch currentElement {
            case "sample-time", "thread-state", "time-sample-kind", "weight":
                // Content will be handled in didEndElement
                break
            default:
                break
            }
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            if elementName == "row" && inSampleRow {
                // Create TimeProfilerSample
                if let timestampStr = currentSample["timestamp"] {
                    // The timestamp is in nanoseconds (raw number in element content)
                    let timestamp = Double(timestampStr) ?? 0

                    let sample = TimeProfilerSample(
                        timestamp: timestamp / 1_000_000_000, // Convert from nanoseconds to seconds
                        threadId: currentSample["threadId"].map { UInt64($0, radix: 16) ?? 0 } ?? 0,
                        threadState: currentSample["threadState"] ?? "Unknown",
                        callstackRef: currentSample["callstackRef"],
                        sampleType: currentSample["sampleType"] ?? "Unknown",
                        coreIndex: Int(currentSample["coreIndex"] ?? ""),
                        weight: 1.0
                    )
                    samples.append(sample)
                }
                inSampleRow = false
                currentSample.removeAll()
            } else if inSampleRow {
                // Handle element content (for text-based elements)
                switch elementName {
                case "sample-time":
                    // The text content contains the raw nanosecond timestamp
                    if !elementContent.isEmpty {
                        currentSample["timestamp"] = elementContent
                    }
                default:
                    break
                }
            }
            currentElement = ""
            elementContent = ""
        }
    }

    /// Parse time profiler samples using proper XMLParser
    static func parseTimeProfiler(_ data: Data) -> [TimeProfilerSample] {
        let parser = TimeProfilerXMLParser()
        return parser.parse(data: data)
    }

    // MARK: - System Call Data

    struct SystemCall {
        let timestamp: TimeInterval
        let threadId: UInt64
        let callName: String
        let duration: TimeInterval
        let waitTime: TimeInterval
        let cpuTime: TimeInterval
        let args: [String]
        let returnValue: Int64
        let success: Bool
    }

    /// XMLParser delegate for system call data
    class SystemCallXMLParser: NSObject, XMLParserDelegate {
        private var syscalls: [SystemCall] = []
        private var currentSyscall: [String: String] = [:]
        private var currentElement = ""
        private var inSyscallRow = false
        private var elementContent = ""
        // Cache fmt values by id for reference resolution
        private var elementCache: [String: String] = [:]

        func parse(data: Data) -> [SystemCall] {
            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
            return syscalls
        }

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
            currentElement = elementName
            elementContent = ""

            switch elementName {
            case "row":
                inSyscallRow = true
                currentSyscall.removeAll()
            case "start-time":
                if let fmt = attributeDict["fmt"] {
                    currentSyscall["timestamp"] = fmt
                    if let id = attributeDict["id"] {
                        elementCache[id] = fmt
                    }
                } else if let ref = attributeDict["ref"], let cached = elementCache[ref] {
                    currentSyscall["timestamp"] = cached
                }
            case "thread":
                if let fmt = attributeDict["fmt"] {
                    // Extract thread ID from format like "Main Thread 0x53996c (Scroll, pid: 30463)"
                    if let hexMatch = fmt.range(of: "0x[0-9a-f]+", options: .regularExpression) {
                        currentSyscall["threadId"] = String(fmt[hexMatch])
                    }
                }
            case "syscall":
                if let fmt = attributeDict["fmt"] {
                    currentSyscall["callName"] = fmt
                    if let id = attributeDict["id"] {
                        elementCache[id] = fmt
                    }
                } else if let ref = attributeDict["ref"], let cached = elementCache[ref] {
                    currentSyscall["callName"] = cached
                }
            case "duration":
                if let fmt = attributeDict["fmt"] {
                    currentSyscall["durationStr"] = fmt
                    if let id = attributeDict["id"] {
                        elementCache[id] = fmt
                    }
                } else if let ref = attributeDict["ref"], let cached = elementCache[ref] {
                    currentSyscall["durationStr"] = cached
                }
            case "syscall-return":
                if let fmt = attributeDict["fmt"] {
                    currentSyscall["returnValue"] = fmt
                    if let id = attributeDict["id"] {
                        elementCache[id] = fmt
                    }
                } else if let ref = attributeDict["ref"], let cached = elementCache[ref] {
                    currentSyscall["returnValue"] = cached
                }
            default:
                break
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            if !inSyscallRow { return }

            let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedString.isEmpty { return }

            elementContent += trimmedString

            switch currentElement {
            case "start-time", "duration", "cputime", "waittime":
                // Content will be handled in didEndElement
                break
            default:
                break
            }
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            if elementName == "row" && inSyscallRow {
                // Create SystemCall object
                if let callName = currentSyscall["callName"] {
                    // Parse timestamp from raw nanoseconds
                    let timestampStr = currentSyscall["timestamp"] ?? "0"
                    let timestamp = Double(timestampStr) ?? 0

                    // Parse duration - could be "4.92 µs" (from fmt attribute) or raw nanoseconds (from content)
                    let durationStr = currentSyscall["durationStr"] ?? elementContent
                    let duration = extractNanoseconds(from: durationStr)

                    let syscall = SystemCall(
                        timestamp: timestamp / 1_000_000_000,
                        threadId: currentSyscall["threadId"].map { UInt64($0, radix: 16) ?? 0 } ?? 0,
                        callName: callName.trimmingCharacters(in: .whitespacesAndNewlines),
                        duration: duration / 1_000_000_000,  // Convert to seconds
                        waitTime: 0,  // Would need separate wait-time element
                        cpuTime: 0,   // Would need separate cpu-time element
                        args: [],
                        returnValue: Int64(currentSyscall["returnValue"] ?? "0") ?? 0,
                        success: true
                    )
                    syscalls.append(syscall)
                }
                inSyscallRow = false
                currentSyscall.removeAll()
            } else if inSyscallRow {
                // Handle element content
                switch elementName {
                case "start-time":
                    currentSyscall["timestamp"] = elementContent
                case "duration":
                    currentSyscall["duration"] = elementContent
                default:
                    break
                }
            }
            currentElement = ""
            elementContent = ""
        }

        /// Extract nanoseconds from formatted duration strings like "4.92 µs" or raw "4917"
        private func extractNanoseconds(from durationStr: String) -> Double {
            if durationStr.contains("µs") {
                // Microseconds
                let numStr = durationStr.replacingOccurrences(of: " µs", with: "")
                return (Double(numStr) ?? 0) * 1000
            } else if durationStr.contains("ms") {
                // Milliseconds
                let numStr = durationStr.replacingOccurrences(of: " ms", with: "")
                return (Double(numStr) ?? 0) * 1_000_000
            } else if durationStr.contains("ns") {
                // Nanoseconds
                let numStr = durationStr.replacingOccurrences(of: " ns", with: "")
                return Double(numStr) ?? 0
            } else {
                // Assume raw nanoseconds
                return Double(durationStr) ?? 0
            }
        }
    }

    /// Parse system calls using proper XMLParser
    static func parseSystemCalls(_ data: Data) -> [SystemCall] {
        let parser = SystemCallXMLParser()
        return parser.parse(data: data)
    }

    // MARK: - Allocation Data

    struct AllocationEvent {
        let timestamp: TimeInterval
        let threadId: UInt64
        let address: UInt64
        let size: Int64
        let type: AllocationType
        let stackTrace: String?
    }

    enum AllocationType {
        case allocate
        case deallocate
        case reallocate

        var isAllocation: Bool {
            switch self {
            case .allocate, .reallocate: return true
            case .deallocate: return false
            }
        }
    }

    /// XMLParser delegate for allocation data
    class AllocationXMLParser: NSObject, XMLParserDelegate {
        private var allocations: [AllocationEvent] = []
        private var currentAllocation: [String: String] = [:]
        private var currentElement = ""
        private var inAllocationRow = false
        private var elementContent = ""

        func parse(data: Data) -> [AllocationEvent] {
            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
            return allocations
        }

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
            currentElement = elementName
            elementContent = ""

            switch elementName {
            case "row":
                inAllocationRow = true
                currentAllocation.removeAll()
            case "timestamp", "address", "size", "type", "stacktrace":
                // Elements with text content
                break
            default:
                break
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            if !inAllocationRow { return }

            let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedString.isEmpty { return }

            elementContent += trimmedString

            switch currentElement {
            case "timestamp", "address", "size", "type":
                // Content will be handled in didEndElement
                break
            default:
                break
            }
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            if elementName == "row" && inAllocationRow {
                // Create AllocationEvent
                if let timestampStr = currentAllocation["timestamp"],
                   let timestamp = Double(timestampStr.replacingOccurrences(of: ".", with: "")) {

                    let type: AllocationType
                    switch currentAllocation["type"]?.lowercased() {
                    case "malloc", "allocate", "new":
                        type = .allocate
                    case "free", "deallocate", "delete":
                        type = .deallocate
                    case "realloc", "reallocate":
                        type = .reallocate
                    default:
                        type = .allocate // Default
                    }

                    let allocation = AllocationEvent(
                        timestamp: timestamp / 1_000_000_000,
                        threadId: 0, // Would need to extract from thread reference
                        address: UInt64(currentAllocation["address"] ?? "0", radix: 16) ?? 0,
                        size: Int64(currentAllocation["size"] ?? "0") ?? 0,
                        type: type,
                        stackTrace: currentAllocation["stacktrace"]
                    )
                    allocations.append(allocation)
                }
                inAllocationRow = false
                currentAllocation.removeAll()
            } else if inAllocationRow {
                // Handle element content
                switch elementName {
                case "timestamp":
                    currentAllocation["timestamp"] = elementContent
                case "address":
                    currentAllocation["address"] = elementContent
                case "size":
                    currentAllocation["size"] = elementContent
                case "type":
                    currentAllocation["type"] = elementContent
                default:
                    break
                }
            }
            currentElement = ""
            elementContent = ""
        }
    }

    /// Parse allocation events using proper XMLParser
    static func parseAllocations(_ data: Data) -> [AllocationEvent] {
        // Check if this is valid allocation data
        guard let xmlString = String(data: data, encoding: .utf8) else { return [] }

        // Skip empty results
        if xmlString.contains("<trace-query-result>") &&
           xmlString.contains("</trace-query-result>") &&
           xmlString.components(separatedBy: .newlines).filter({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }).count <= 3 {
            return []
        }

        let parser = AllocationXMLParser()
        return parser.parse(data: data)
    }

    // MARK: - Analysis Methods

    /// Extract top CPU symbols from time profiler samples within a time window
    static func extractTopSymbols(
        from samples: [TimeProfilerSample],
        in timeWindow: (start: TimeInterval, end: TimeInterval),
        topCount: Int = 3
    ) -> [CallstackSymbol] {
        // Filter samples in time window
        let windowSamples = samples.filter { sample in
            sample.timestamp >= timeWindow.start &&
            sample.timestamp <= timeWindow.end
        }

        // Count samples by thread state and sample type
        var stateWeights: [String: Double] = [:]
        var typeWeights: [String: Double] = [:]

        for sample in windowSamples {
            let state = sample.threadState.isEmpty ? "unknown" : sample.threadState
            let type = sample.sampleType.isEmpty ? "unknown" : sample.sampleType

            stateWeights[state, default: 0] += sample.weight
            typeWeights[type, default: 0] += sample.weight
        }

        let totalWeight = windowSamples.reduce(0) { $0 + $1.weight }

        if totalWeight == 0 {
            return []
        }

        // Prefer state information as it's more meaningful
        // Top states: Running, Blocked, etc.
        return stateWeights.sorted { $0.value > $1.value }
            .prefix(topCount)
            .map { state, weight in
                CallstackSymbol(
                    address: 0,
                    symbolName: state,
                    moduleName: nil,
                    imageName: nil,
                    percent: (weight / totalWeight) * 100.0
                )
            }
    }

    /// Determine dominant wait state from system calls in a time window
    static func extractWaitState(
        from syscalls: [SystemCall],
        in timeWindow: (start: TimeInterval, end: TimeInterval)
    ) -> String {
        let windowCalls = syscalls.filter { syscall in
            syscall.timestamp >= timeWindow.start &&
            syscall.timestamp <= timeWindow.end
        }

        // Classify by wait time dominance
        let totalWaitTime = windowCalls.reduce(0) { $0 + $1.waitTime }

        if totalWaitTime > 0.001 { // 1ms threshold
            // Find the syscall with most wait time
            if let dominantCall = windowCalls.max(by: { $0.waitTime < $1.waitTime }) {
                // Extract wait type from call name
                if dominantCall.callName.contains("kevent") {
                    return "kevent"
                } else if dominantCall.callName.contains("futex") {
                    return "futex"
                } else if dominantCall.callName.contains("read") {
                    return "read"
                } else if dominantCall.callName.contains("write") {
                    return "write"
                } else if dominantCall.callName.contains("mach_msg") {
                    return "mach_msg"
                } else if dominantCall.callName.contains("select") {
                    return "select"
                } else if dominantCall.callName.contains("poll") {
                    return "poll"
                } else {
                    return dominantCall.callName
                }
            }
        }

        return "cpu"
    }

    /// Calculate allocation delta for a time window
    static func calculateAllocationDelta(
        from allocations: [AllocationEvent],
        in timeWindow: (start: TimeInterval, end: TimeInterval)
    ) -> Int64 {
        let windowAllocations = allocations.filter { allocation in
            allocation.timestamp >= timeWindow.start &&
            allocation.timestamp <= timeWindow.end
        }

        return windowAllocations.reduce(0) { total, allocation in
            if allocation.type.isAllocation {
                return total + allocation.size
            } else {
                return total - allocation.size
            }
        }
    }
}

// MARK: - Legacy Compatibility

extension MultiInstrumentParser {

    /// Legacy allocation delta structure for backward compatibility
    struct AllocationDelta {
        let timestamp: TimeInterval
        let bytesAllocated: Int64
        let bytesDeallocated: Int64
        let allocationCount: Int
        let deallocationCount: Int
    }

    /// Legacy allocation parsing method
    static func parseAllocationDeltas(_ data: Data) -> [AllocationDelta] {
        let events = parseAllocations(data)

        // Group events by time windows (e.g., per second)
        let timeGroups = Dictionary(grouping: events) { event in
            Int(event.timestamp)
        }

        return timeGroups.map { timestamp, events in
            let allocations = events.filter { $0.type.isAllocation }
            let deallocations = events.filter { !$0.type.isAllocation }

            let bytesAllocated = allocations.reduce(0) { $0 + $1.size }
            let bytesDeallocated = deallocations.reduce(0) { $0 + $1.size }

            return AllocationDelta(
                timestamp: Double(timestamp),
                bytesAllocated: bytesAllocated,
                bytesDeallocated: bytesDeallocated,
                allocationCount: allocations.count,
                deallocationCount: deallocations.count
            )
        }.sorted { $0.timestamp < $1.timestamp }
    }
}