#!/usr/bin/env swift

import ArgumentParser
import Foundation

@main
struct TestParser: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Test ArgumentParser"
    )

    @Argument(help: "Test file path")
    var filePath: String

    @Flag(name: .long, help: "Verbose output")
    var verbose: Bool = false

    func run() throws {
        print("✅ TEST PARSER EXECUTING!")
        print("📁 File path: \(filePath)")
        print("🔍 Verbose: \(verbose)")
        print("🎉 ArgumentParser works!")
    }
}