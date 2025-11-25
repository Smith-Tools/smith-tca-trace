#!/bin/bash

# Simple wrapper to run TCA trace analysis
TRACE_PATH="/Volumes/Plutonian/_Developer/Scroll/source/Scroll/TCA_Instruments_Integration/Untitled.trace"

echo "🔍 Running TCA Trace Analysis"
echo "📍 Trace: $TRACE_PATH"
echo "🔧 Using smith-tca-trace tool..."

# Try different approaches to run the analysis
echo ""
echo "📊 Attempt 1: Direct execution with explicit path"
./.build/debug/smith-tca-trace analyze "$TRACE_PATH" --mode compact

echo ""
echo "📊 Attempt 2: Using relative path"
./.build/debug/smith-tca-trace analyze ./Untitled.trace --mode compact

echo ""
echo "📊 Attempt 3: With absolute path and explicit flags"
./.build/debug/smith-tca-trace analyze --mode compact --verbose "$TRACE_PATH"