---
name: smith-tca-trace
description: TCA performance profiling and analysis. Automatically triggers for:
             TCA performance, signposts, Instruments traces, slow reducers,
             effect lifecycle, action timing, TCA optimization
allowed-tools: [Bash, Read, Write]
executables: ["~/.local/bin/smith-tca-trace", "./Scripts/smith-tca-trace", "smith-tca-trace"]
---

# TCA Performance Analysis

Analyzes The Composable Architecture (TCA) applications using Instruments traces.

## Automatic Usage

This skill activates when users ask about:
- "Analyze this Instruments trace"
- "Why is my TCA reducer slow?"
- "Profile my TCA app"
- "Find performance bottlenecks in TCA"

## Commands

**Analyze trace** (AI-optimized by default):
```bash
./scripts/tca-trace analyze /path/to/trace.trace
# Returns: Compact JSON (~200-500 tokens vs 2000+ for full trace)

Get full details (when AI needs complete data):
./scripts/tca-trace analyze /path/to/trace.trace --mode agent
# Returns: Full JSON (use sparingly - large context)

Compare traces (regression detection):
./scripts/tca-trace compare baseline.trace current.trace
# Returns: Compact comparison with regressions/improvements only
```

## Progressive Disclosure Pattern (AI Workflow)

**Step 1: Get summary**
```bash
tca-trace analyze trace.trace
```
AI sees: "8 actions, 2 slow (ReadingLibrary.selectArticle: 45ms, ...)"

**Step 2: AI requests details for specific action**
```bash
tca-trace analyze trace.trace --filter "ReadingLibrary.selectArticle" --mode agent
```
Returns: Full details for just that action

**Step 3: If needed, get complete trace**
```bash
tca-trace analyze trace.trace --mode agent
```

## Output Modes (Token Efficiency)

- **--mode compact**: DEFAULT - Token-optimized for AI agents (30-40% reduction)
  - Summary + top 10 slow actions + top 5 features
  - ~200-500 tokens for typical trace
- **--mode agent**: Full data - use only when AI explicitly needs complete trace
  - All actions, effects, shared state changes
  - ~2000-5000 tokens for typical trace
- **--mode user**: Human-friendly markdown with emoji
  - Formatted for terminal display

## Technical Details

Uses Apple's Instruments os_signpost data to extract TCA action timing,
effect lifecycles, shared state changes, and performance metrics.

## Integration Examples

**Performance Investigation:**
```
User: "My TCA app feels sluggish, can you help?"
AI: [Activates tca-trace skill] "I'll analyze your Instruments trace to identify performance bottlenecks."
```

**Regression Detection:**
```
User: "After the last update, my app is slower"
AI: [Uses tca-trace] "Let me compare before/after traces to detect what changed."
```

**Architecture Analysis:**
```
User: "Is this TCA implementation well-structured?"
AI: [Analyzes trace] "Based on the action flow and state changes, here are some optimization suggestions..."
```