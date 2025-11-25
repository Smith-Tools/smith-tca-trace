import Foundation

/// Parses XML output from xctrace to extract signpost events
@available(macOS 14, *)
struct SignpostXMLParser: Sendable {
    /// Parse XML data to extract signpost events
    func parse(data: Data) throws -> [SignpostEvent] {
        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw TCATraceError.parsingError("Unable to convert XML data to string")
        }

        return try parse(xmlString: xmlString)
    }

    /// Parse XML string to extract signpost events
    func parse(xmlString: String) throws -> [SignpostEvent] {
        var signposts: [SignpostEvent] = []
        let lines = xmlString.components(separatedBy: .newlines)

        for line in lines {
            // Skip header and empty lines
            if line.isEmpty || line.contains("<?xml") || line.contains("<trace-toc") || line.contains("<table") {
                continue
            }

            // Parse CSV-style lines that xctrace exports
            let fields = line.components(separatedBy: "\t")
            guard fields.count >= 6 else { continue }

            // Expected format: timestamp, subsystem, category, name, type, message
            let timestampString = fields[0].trimmingCharacters(in: .whitespaces)
            let subsystem = fields[1].trimmingCharacters(in: .whitespaces)
            let category = fields[2].trimmingCharacters(in: .whitespaces)
            let name = fields[3].trimmingCharacters(in: .whitespaces)
            let typeString = fields[4].trimmingCharacters(in: .whitespaces)
            let message = fields.count > 5 ? fields[5].trimmingCharacters(in: .whitespaces) : ""

            // Parse timestamp
            guard let timestamp = Double(timestampString) else { continue }

            // Parse event type
            guard let eventType = SignpostEvent.EventType(rawValue: typeString.lowercased()) else { continue }

            // Create unique ID from timestamp, name, and type
            let id = "\(timestamp)_\(name)_\(typeString)"

            let signpost = SignpostEvent(
                id: id,
                timestamp: timestamp,
                subsystem: subsystem,
                category: category,
                name: name,
                message: message,
                type: eventType
            )

            signposts.append(signpost)
        }

        return signposts
    }

    /// Parse more structured XML format (alternative export format)
    func parseStructuredXML(data: Data) throws -> [SignpostEvent] {
        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw TCATraceError.parsingError("Unable to convert XML data to string")
        }

        // This would need proper XML parsing with XMLDocument or similar
        // For now, we'll fall back to line-based parsing
        return try parse(xmlString: xmlString)
    }

    /// Filter signposts for TCA-related events (works with any app's subsystem)
    func filterTCASignposts(_ signposts: [SignpostEvent], subsystemFilter: String? = nil) -> [SignpostEvent] {
        return signposts.filter { signpost in
            // Check subsystem filter if provided
            if let filter = subsystemFilter {
                guard signpost.subsystem.contains(filter) else { return false }
            }

            // Check for TCA-related categories and naming patterns
            let isTCACategory = signpost.category.contains("TCA") ||
                              signpost.category.contains("State") ||
                              signpost.category.contains("Action") ||
                              signpost.category.contains("Effect")

            let isTCAName = signpost.name.contains("Feature") ||
                          signpost.name.contains("Reducer") ||
                          signpost.name.contains("Effect") ||
                          signpost.name.contains("Action") ||
                          signpost.name.hasSuffix("Feature") ||
                          signpost.name.contains(".")

            return isTCACategory || isTCAName
        }
    }
}