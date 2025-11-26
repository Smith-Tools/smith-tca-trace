import Foundation

/// Errors that can occur during TCA trace analysis
enum TCATraceError: LocalizedError, Sendable {
    case fileNotFound(String)
    case invalidTraceFile(String)
    case xctraceExportFailed(Int32)
    case parsingError(String)
    case noTCADataFound(message: String? = nil)
    case storageError(String)
    case comparisonError(String)
    case noProjectFound(message: String)
    case noTracesFound(message: String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .invalidTraceFile(let path):
            return "Invalid trace file: \(path)"
        case .xctraceExportFailed(let code):
            return "xctrace export failed with exit code: \(code)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        case .noTCADataFound(let message):
            return message ?? "No TCA signpost data found in trace file"
        case .storageError(let message):
            return "Storage error: \(message)"
        case .comparisonError(let message):
            return "Comparison error: \(message)"
        case .noProjectFound(let message):
            return message
        case .noTracesFound(let message):
            return message
        }
    }
}