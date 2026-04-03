# GlassUsage

A native macOS menu bar app + desktop widget that shows live Claude CLI usage stats — rate limits, token counts, and session data — mirroring what you'd see at `claude.ai/settings/usage`.

## What it shows

- **Weekly limit %** (7-day unified quota) with color coding: green → orange → red
- **5-Hour limit %** (rolling session quota)
- **Opus / Sonnet per-model quotas** (7-day)
- **Extra usage** (credit spend vs monthly cap, if enabled)
- **Local session stats** — output tokens, cache reads, API call count — parsed live from `~/.claude/projects/**/*.jsonl`
- **Auto-refreshes** every 15 minutes; menu bar app pings the widget on every successful fetch

## Architecture

```
GlassUsage (MenuBarExtra app)
├── Shared/
│   ├── Models.swift       — RateLimit, Utilization, SessionStats, WidgetState, AuthError
│   ├── APIClient.swift    — Keychain read + api.anthropic.com/api/oauth/usage fetch
│   └── UsageParser.swift  — JSONL session parser (~/.claude/projects/**/*.jsonl)
├── GlassUsage/
│   ├── GlassUsageApp.swift   — MenuBarExtra scene (no dock icon)
│   └── ContentView.swift     — Full usage view with rate limit bars + session stats
└── GlassUsageWidget/
    └── GlassUsageWidget.swift — WidgetKit extension (Small / Medium / Large / XL)
```

## How the data flows

**Rate limits (% used):**
The Anthropic API endpoint `https://api.anthropic.com/api/oauth/usage` returns current utilization for each quota window. Auth uses the OAuth token stored by Claude CLI in the macOS Keychain under the service name `Claude Code-credentials`, with the required header `anthropic-beta: oauth-2025-04-20`.

**Local session stats:**
Parsed directly from `~/.claude/projects/**/*.jsonl`. Each `assistant` role entry contains a `usage` object with input/output/cache token counts. No API call required.

## Setup (development)

### Requirements
- macOS 14+
- Xcode 16+ (tested on Xcode 26.5 beta / macOS 26 beta)
- [xcodegen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- Claude CLI installed and logged in (`claude` in terminal)
- Apple ID added to Xcode (Xcode → Settings → Accounts) for signing

### Build & run

```bash
cd GlassUsage
xcodegen generate
open GlassUsage.xcodeproj
# Select GlassUsage scheme → ⌘R
```

The app runs as a menu bar item (waveform icon). No dock icon, no window.

### Adding the desktop widget

1. Run the app at least once from Xcode (⌘R on the GlassUsage scheme)
2. Allow the app in System Settings → Privacy & Security if prompted
3. Right-click the desktop → Edit Widgets → search "GlassUsage" → drag Large size onto desktop

### Important: Sandbox requirement (macOS 26+)

The widget extension **must** have `com.apple.security.app-sandbox = true` in its entitlements. macOS 26 silently refuses to register non-sandboxed WidgetKit extensions with pluginkit — no error, no log, the widget simply won't appear in the gallery.

The entitlements include sandbox exceptions for network access (API calls) and read-only access to `~/.claude/` (session data). See `learning.md` for the full debugging story.

## Quit

Click the waveform `◎` icon in the menu bar → **Quit GlassUsage** (or ⌘Q).
