import Foundation

/// Extracts TCA actions from signpost events
@available(macOS 14, *)
struct SignpostExtractor: Sendable {
    /// Extract TCA actions from signpost events
    func extractActions(from signposts: [SignpostEvent]) -> [TCAAction] {
        var actions: [TCAAction] = []
        var eventMap: [String: SignpostEvent] = [:]

        // Generic TCA detection based on Point Free patterns and real-world signatures
        let tcaSignposts = signposts.filter { signpost in
            isTCASignpost(signpost)
        }

        // Sort TCA signposts by timestamp to ensure proper matching
        let sortedSignposts = tcaSignposts.sorted { $0.timestamp < $1.timestamp }

        for signpost in sortedSignposts {
            switch signpost.type {
            case .begin:
                eventMap[signpost.id] = signpost
            case .end:
                if let beginEvent = eventMap[signpost.id] {
                    let action = createAction(from: beginEvent, to: signpost)
                    actions.append(action)
                    eventMap.removeValue(forKey: signpost.id)
                }
            case .event:
                // Single event without begin/end, create action from message if it's a TCA action
                let actionName = extractActionName(from: signpost.name, message: signpost.message)
                let featureName = extractFeatureName(from: signpost.name, message: signpost.message)

                let action = TCAAction(
                    featureName: featureName,
                    actionName: actionName,
                    timestamp: signpost.timestamp,
                    duration: 0,
                    metadata: signpost.message.isEmpty ? nil : signpost.message
                )
                actions.append(action)
            }
        }

        return actions.sorted { $0.timestamp < $1.timestamp }
    }

    /// Extract TCA effects from signpost events
    func extractEffects(from signposts: [SignpostEvent]) -> [TCAEffect] {
        var effects: [TCAEffect] = []
        var effectMap: [String: SignpostEvent] = [:]

        // Generic TCA effect detection
        let tcaEffectSignposts = signposts.filter { signpost in
            isTCAEffectSignpost(signpost)
        }

        let sortedSignposts = tcaEffectSignposts.sorted { $0.timestamp < $1.timestamp }

        for signpost in sortedSignposts {

            switch signpost.type {
            case .begin:
                effectMap[signpost.id] = signpost
            case .end:
                if let beginEvent = effectMap[signpost.id] {
                    let effect = TCAEffect(
                        name: extractEffectName(from: beginEvent.name),
                        featureName: extractFeatureName(from: beginEvent.name),
                        startTime: beginEvent.timestamp,
                        endTime: signpost.timestamp
                    )
                    effects.append(effect)
                    effectMap.removeValue(forKey: signpost.id)
                }
            case .event:
                // Single effect event
                let effect = TCAEffect(
                    name: extractEffectName(from: signpost.name),
                    featureName: extractFeatureName(from: signpost.name),
                    startTime: signpost.timestamp,
                    endTime: signpost.timestamp + 0.001 // Small default duration
                )
                effects.append(effect)
            }
        }

        return effects.sorted { $0.startTime < $1.startTime }
    }

    /// Extract shared state changes from signpost events
    func extractSharedStateChanges(from signposts: [SignpostEvent]) -> [SharedStateChange] {
        return signposts.compactMap { signpost in
            guard signpost.name.contains("State") ||
                  signpost.name.contains("SharedState") ||
                  signpost.message.contains("state") ||
                  signpost.category.contains("State") else {
                return nil
            }

            let stateInfo = parseStateMessage(signpost.message)
            return SharedStateChange(
                featureName: extractFeatureName(from: signpost.name),
                timestamp: signpost.timestamp,
                property: stateInfo.property,
                oldValue: stateInfo.oldValue,
                newValue: stateInfo.newValue
            )
        }.sorted { $0.timestamp < $1.timestamp }
    }

    private func createAction(from beginEvent: SignpostEvent, to endEvent: SignpostEvent) -> TCAAction {
        return TCAAction(
            featureName: extractFeatureName(from: beginEvent.name),
            actionName: extractActionName(from: beginEvent.name),
            timestamp: beginEvent.timestamp,
            duration: endEvent.timestamp - beginEvent.timestamp,
            metadata: beginEvent.message.isEmpty ? nil : beginEvent.message
        )
    }

    private func extractFeatureName(from name: String) -> String {
        // Parse "ReadingLibraryFeature.selectArticle" -> "ReadingLibrary"
        let components = name.components(separatedBy: ".")
        let firstComponent = components.first ?? name

        // Remove "Feature" suffix if present
        return firstComponent.replacingOccurrences(of: "Feature", with: "")
    }

    private func extractFeatureName(from name: String, message: String) -> String {
        // First try normal extraction
        let normalFeature = extractFeatureName(from: name)
        if normalFeature != name {
            return normalFeature
        }

        // Extract from message like "[ScrollApp]  ReadingLibraryFeature.Action.sidebarSelectionChanged"
        if message.contains("Feature") {
            let pattern = #"(\w+Feature)\."#
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: message, range: NSRange(message.startIndex..., in: message)) {
                if let featureRange = Range(match.range(at: 1), in: message) {
                    let featureName = String(message[featureRange])
                    return featureName.replacingOccurrences(of: "Feature", with: "")
                }
            }
        }

        return name == "Action" ? "Unknown" : normalFeature
    }

    private func extractActionName(from name: String) -> String {
        // Parse various TCA action formats:
        // "ReadingLibraryFeature.selectArticle" -> "selectArticle"
        // "ReadingLibraryFeature.Action.selectArticle" -> "selectArticle"
        // "Action" from message parsing -> extract from message

        if name == "Action" {
            return "TCAAction" // Placeholder for message-based actions
        }

        let components = name.components(separatedBy: ".")

        // Handle "Feature.Action.actionName" pattern
        if components.count >= 3 && components[1] == "Action" {
            return components.dropFirst(2).joined(separator: ".")
        }

        // Handle "Feature.actionName" pattern
        if components.count >= 2 {
            return components.dropFirst().joined(separator: ".")
        }

        return name
    }

    private func extractActionName(from name: String, message: String) -> String {
        // First try normal extraction
        let normalAction = extractActionName(from: name)
        if normalAction != name && normalAction != "TCAAction" {
            return normalAction
        }

        // Extract from message like "[ScrollApp]  ReadingLibraryFeature.Action.sidebarSelectionChanged"
        let pattern = #"Feature\.Action\.([\w.()]+)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: message, range: NSRange(message.startIndex..., in: message)) {
            if let actionRange = Range(match.range(at: 1), in: message) {
                return String(message[actionRange])
            }
        }

        return normalAction
    }

    private func extractEffectName(from name: String) -> String {
        // Extract effect name from signpost name
        if name.contains("Effect") {
            // "MyFeature.someEffect" -> "someEffect"
            let components = name.components(separatedBy: ".")
            return components.last ?? name
        }
        return name
    }

    private func parseStateMessage(_ message: String) -> (property: String, oldValue: String?, newValue: String?) {
        // Parse state change message like "property: oldValue -> newValue"
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedMessage.contains("->") {
            let parts = trimmedMessage.components(separatedBy: "->")
            guard parts.count >= 2 else {
                return (trimmedMessage, nil, nil)
            }

            let propertyPart = parts[0].trimmingCharacters(in: .whitespaces)
            let newValuePart = parts[1].trimmingCharacters(in: .whitespaces)

            if propertyPart.contains(":") {
                let propParts = propertyPart.components(separatedBy: ":")
                let property = propParts[0].trimmingCharacters(in: .whitespaces)
                let oldValue = propParts.count > 1 ? propParts[1].trimmingCharacters(in: .whitespaces) : nil
                return (property, oldValue, newValuePart)
            }

            return (propertyPart, nil, newValuePart)
        } else if trimmedMessage.contains(":") {
            let parts = trimmedMessage.components(separatedBy: ":")
            let property = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : nil
            return (property, nil, value)
        }

        return (trimmedMessage, nil, nil)
    }

    // MARK: - Generic TCA Detection

    /// Generic detection of TCA-related signposts based on patterns rather than hardcoding
    private func isTCASignpost(_ signpost: SignpostEvent) -> Bool {
        // 1. Direct TCA indicators
        if signpost.subsystem.hasSuffix("app") && !signpost.subsystem.hasPrefix("com.apple.") {
            return true
        }

        if signpost.category == "TCA" {
            return true
        }

        // 2. Point Free TCA signpost patterns
        if signpost.name.contains("_SignpostReducer") ||
           signpost.name.contains("effectSignpost") {
            return true
        }

        // 3. TCA action patterns in messages
        if hasTCAActionPattern(in: signpost.message) {
            return true
        }

        // 4. TCA naming conventions
        if signpost.name == "Action" && hasTCAActionPattern(in: signpost.message) {
            return true
        }

        // 5. Exclude obvious system signposts
        if isSystemSignpost(signpost) {
            return false
        }

        // 6. Heuristic: app-specific but not Apple system
        if signpost.subsystem.contains(".") &&
           !signpost.subsystem.hasPrefix("com.apple.") &&
           (signpost.name.contains("Feature") || signpost.name.contains("Action") || signpost.name.contains("Effect")) {
            return true
        }

        return false
    }

    /// Generic detection of TCA effects specifically
    private func isTCAEffectSignpost(_ signpost: SignpostEvent) -> Bool {
        // Must be effect-related
        guard signpost.name.contains("Effect") || signpost.category.contains("Effect") else {
            return false
        }

        // Exclude system effects
        guard !signpost.subsystem.hasPrefix("com.apple.") else {
            return false
        }

        // Include app-specific effects
        if signpost.subsystem.hasSuffix("app") {
            return true
        }

        // TCA effect patterns from Point Free instrumentation
        if signpost.name.contains("Started from") ||
           signpost.name.contains("Output from") ||
           signpost.name.contains("Finished") {
            return true
        }

        // Effect-related signposts with TCA patterns
        if hasTCAActionPattern(in: signpost.message) {
            return true
        }

        return false
    }

    /// Detect TCA action patterns in messages using regex
    private func hasTCAActionPattern(in message: String) -> Bool {
        // Pattern: Feature.Action.actionName
        let featureActionPattern = #"(\w+)Feature\.Action\.([\w.()]+)"#
        if let regex = try? NSRegularExpression(pattern: featureActionPattern),
           regex.firstMatch(in: message, range: NSRange(message.startIndex..., in: message)) != nil {
            return true
        }

        // Pattern: [FeatureName] context
        let contextPattern = #"\[\w+\].*Feature"#
        if let regex = try? NSRegularExpression(pattern: contextPattern),
           regex.firstMatch(in: message, range: NSRange(message.startIndex..., in: message)) != nil {
            return true
        }

        return false
    }

    /// Detect system signposts to exclude
    private func isSystemSignpost(_ signpost: SignpostEvent) -> Bool {
        // Apple system subsystems
        if signpost.subsystem.hasPrefix("com.apple.") {
            return true
        }

        // System-level operations
        let systemNames = [
            "UpdateTiming", "UpdateSequence", "EventDispatch", "IdleWork", "Commit",
            "CompileShader", "CA::", "CI::", "SLSTransaction", "RenderTask",
            "modeEventProcessing", "stepIdle", "modeScheduling"
        ]

        return systemNames.contains { signpost.name.contains($0) }
    }
}