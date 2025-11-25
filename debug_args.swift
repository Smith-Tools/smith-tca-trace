#!/usr/bin/env swift

import ArgumentParser
import Foundation

@main
struct TestCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Test command",
        subcommands: [Analyze.self],
        defaultSubcommand: Analyze.self
    )

    struct Analyze: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Test analyze command"
        )

        @Argument(help: "Path to file")
        var filePath: String

        @Flag(name: .long, help: "Verbose output")
        var verbose: Bool = false

        func run() throws {
            print("✅ Analyze command executed!")
            print("📁 File path: \(filePath)")
            print("🔍 Verbose: \(verbose)")

            if verbose {
                print("🎯 This is working!")
            }
        }
    }
}