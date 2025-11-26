---
name: smith-tca-trace
description: TCA performance profiling and analysis with automatic trace discovery.
             Automatically triggers for: TCA performance, signposts, Instruments traces,
             slow reducers, effect lifecycle, action timing, TCA optimization
allowed-tools: [Bash, Read, Write]
executables: ["~/.local/bin/smith-tca-trace", "./Scripts/smith-tca-trace", "smith-tca-trace"]
---

# TCA Performance Analysis

Analyzes The Composable Architecture (TCA) applications using Instruments traces
from the canonical per-project location: `<project-root>/.instruments/traces/`

## Canonical Trace Location

**smith-tca-trace automatically discovers traces** from the standard per-project location:

```
<project-root>/.instruments/traces/
```

The tool uses intelligent fallback priority to find traces:

1. **Explicit path** - If user provides `smith-tca-trace analyze /path/to/trace.trace`
2. **Project discovery** - Walks up directory tree to find `Package.swift`, `.xcodeproj`, or `.git`
3. **Canonical location** - Looks in `.instruments/traces/` subdirectory
4. **Smart selection** (in order):
   - `current.trace` (explicit current marker)
   - `baseline.trace` (reference baseline)
   - Most recent trace by modification time
   - Only trace if just one exists

This enables **automatic analysis without user intervention** when invoked by Smith agent.

## Automatic Usage

This skill activates when users ask about:
- "Analyze my TCA performance"
- "Why is my TCA reducer slow?"
- "Profile my TCA app"
- "Find performance bottlenecks in TCA"
- "Compare performance before/after optimization"

## Commands

**Auto-discover and analyze trace** (from canonical location):
```bash
smith-tca-trace analyze
# Automatically finds and analyzes latest/current trace
```

**Analyze specific trace**:
```bash
smith-tca-trace analyze /path/to/trace.trace
# Uses explicit path (bypasses discovery)
```

**Compare traces** (regression detection):
```bash
smith-tca-trace compare baseline.trace current.trace
# Analyzes performance differences
```

**Output modes**:
```bash
smith-tca-trace analyze --mode compact   # Token-optimized (default)
smith-tca-trace analyze --mode agent     # Full data for AI analysis
smith-tca-trace analyze --mode user      # Human-friendly markdown
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

## Setup: Recording Traces

**Option 1: Using Instruments GUI**
```bash
1. Open Instruments in Xcode
2. Select "System Trace" or "Time Profiler"
3. Profile your TCA app
4. Save trace to: <project-root>/.instruments/traces/current.trace
5. Then run: smith-tca-trace analyze
```

**Option 2: Using Instruments CLI** (for automation)
```bash
mkdir -p .instruments/traces
instruments -t 'System Trace' \
  -o .instruments/traces/$(date +%Y%m%d_%H%M%S).trace \
  -D YourApp
smith-tca-trace analyze
```

**Option 3: CI/CD Pipeline**
```yaml
# GitHub Actions example
- name: Profile Performance
  run: |
    instruments -t 'System Trace' \
      -o .instruments/traces/ci_$(date +%s).trace \
      -D MyApp

- name: Analyze with smith-tca-trace
  run: smith-tca-trace analyze
```

## Gitignore Configuration

Add to your `.gitignore` to exclude large trace files:
```
# Instruments profiles (large binary files)
.instruments/traces/
```

You may want to keep baseline traces in source control:
```
# Alternative: commit baseline, exclude current
!.instruments/traces/baseline.trace
.instruments/traces/*.trace
```

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