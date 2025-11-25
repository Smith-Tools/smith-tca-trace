import Foundation

/// Extracts TCA actions from signpost events
@available(macOS 14, *)
struct SignpostExtractor: Sendable {
    /// Extract TCA actions from signpost events
    func extractActions(from signposts: [SignpostEvent]) -> [TCAAction] {
        var actions: [TCAAction] = []
        var eventMap: [String: SignpostEvent] = [:]

        // Sort signposts by timestamp to ensure proper matching
        let sortedSignposts = signposts.sorted { $0.timestamp < $1.timestamp }

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
                // Single event without begin/end, create zero-duration action
                let action = TCAAction(
                    featureName: extractFeatureName(from: signpost.name),
                    actionName: extractActionName(from: signpost.name),
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

        let sortedSignposts = signposts.sorted { $0.timestamp < $1.timestamp }

        for signpost in sortedSignposts {
            // Look for effect-related signposts
            guard signpost.name.contains("Effect") ||
                  signpost.name.contains("effect") ||
                  signpost.category.contains("Effect") else {
                continue
            }

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

    private func extractActionName(from name: String) -> String {
        // Parse "ReadingLibraryFeature.selectArticle" -> "selectArticle"
        let components = name.components(separatedBy: ".")
        return components.last ?? name
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
}