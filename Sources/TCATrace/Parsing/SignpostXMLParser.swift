import Foundation

/// Parses XML output from xctrace to extract signpost events
@available(macOS 14, *)
struct SignpostXMLParser: Sendable {
    /// Parse XML data to extract signpost events
    func parse(data: Data) throws -> [SignpostEvent] {
        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw TCATraceError.parsingError("Unable to convert XML data to string")
        }

        // First try lightweight line-based parsing (older xctrace export style)
        let lineParsed = try parse(xmlString: xmlString)
        if !lineParsed.isEmpty {
            return lineParsed
        }

        // Fallback to structured XML rows (modern xctrace export)
        return try parseStructuredXML(data: data)
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

    /// Parse structured XML rows produced by xctrace export (table schema)
    func parseStructuredXML(data: Data) throws -> [SignpostEvent] {
        let parser = StructuredSignpostParser()
        return try parser.parse(data: data)
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

// MARK: - Structured XML parser

@available(macOS 14, *)
private final class StructuredSignpostParser: NSObject, XMLParserDelegate {
    private var currentElement: String = ""
    private var currentValue: String = ""
    private var currentAttributes: [String: String] = [:]

    private var timestampNS: Double?
    private var subsystem: String?
    private var category: String?
    private var name: String?
    private var identifier: String?
    private var messageParts: [String] = []
    private var eventType: SignpostEvent.EventType?

    private var signposts: [SignpostEvent] = []
    private var valueLookup: [String: String] = [:]

    func parse(data: Data) throws -> [SignpostEvent] {
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = self
        guard xmlParser.parse() else {
            throw TCATraceError.parsingError("XML parsing failed: \(xmlParser.parserError?.localizedDescription ?? "unknown error")")
        }
        return signposts
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentValue = ""
        currentAttributes = attributeDict
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let value = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)

        // If element has ref, try to resolve from lookup
        let resolvedValue: String = {
            if let ref = currentAttributes["ref"], let v = valueLookup[ref] { return v }
            return value
        }()

        // Store id -> value for future ref lookups
        if let id = currentAttributes["id"], !resolvedValue.isEmpty {
            valueLookup[id] = resolvedValue
        }

        switch elementName {
        case "event-time":
            if let ns = Double(resolvedValue) {
                timestampNS = ns
            }
        case "subsystem":
            if !resolvedValue.isEmpty { subsystem = resolvedValue }
        case "category":
            if !resolvedValue.isEmpty { category = resolvedValue }
        case "signpost-name":
            if !resolvedValue.isEmpty { name = resolvedValue }
        case "os-log-metadata", "narrative-text", "fixed-decimal", "uint64", "uint64-hex-lowercase", "uint64-hex-upper-case", "int64", "string", "format-string":
            if !resolvedValue.isEmpty {
                messageParts.append(resolvedValue)
            }
        case "os-signpost-identifier":
            if !resolvedValue.isEmpty {
                identifier = resolvedValue
            }
        case "event-type":
            let v = resolvedValue.lowercased()
            switch v {
            case "begin": eventType = .begin
            case "end": eventType = .end
            default: eventType = .event
            }
        case "row":
            // finalize one signpost row
            if let tsNS = timestampNS,
               let subsystem = subsystem,
               let category = category,
               let name = name,
               let type = eventType {

                let timestampSeconds = tsNS / 1_000_000_000.0
                let message = messageParts.joined(separator: " ")
                let id = identifier ?? "\(tsNS)_\(name)_\(type.rawValue)"

                let signpost = SignpostEvent(
                    id: id,
                    timestamp: timestampSeconds,
                    subsystem: subsystem,
                    category: category,
                    name: name,
                    message: message,
                    type: type
                )
                signposts.append(signpost)
            }

            // reset for next row
            timestampNS = nil
            subsystem = nil
            category = nil
            name = nil
            identifier = nil
            messageParts = []
            eventType = nil

        default:
            break
        }

        currentValue = ""
    }
}
