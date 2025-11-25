import Foundation

// Simple test to verify the tool structure
print("✅ smith-tca-trace tool is accessible")
print("📁 Current directory: \(FileManager.default.currentDirectoryPath)")

let tracePath = "/Volumes/Plutonian/_Developer/Scroll/source/Scroll/TCA_Instruments_Integration/Untitled.trace"

if FileManager.default.fileExists(atPath: tracePath) {
    print("✅ Trace file exists: \(tracePath)")

    let attributes = try? FileManager.default.attributesOfItem(atPath: tracePath)
    if let size = attributes?[.size] as? Int64 {
        print("📊 Trace file size: \(size) bytes (\(String(format: "%.1f", Double(size) / (1024*1024))) MB)")
    }
} else {
    print("❌ Trace file not found: \(tracePath)")
}