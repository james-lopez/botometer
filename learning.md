# GlassUsage — Lessons Learned

## 1. Widget Registration Requires Sandbox (macOS 26)

### Symptom
Menu bar app ran fine from Xcode, but the widget never appeared in the macOS widget gallery. No error, no log, completely silent.

### Root Cause
**macOS 26 requires `com.apple.security.app-sandbox = true` on WidgetKit extensions.** If sandbox is `false`, pluginkit silently refuses to register. No log entry, no error code, no feedback.

### Fix
In `GlassUsageWidget.entitlements`:
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.temporary-exception.files.home-relative-path.read-only</key>
<array>
    <string>/.claude/</string>
</array>
```

### Red Herrings
| Suspect | Outcome |
|---|---|
| GateKeeper / `spctl --assess` rejected | macOS 26 removed `spctl --add`; System Settings "allow everywhere" didn't help |
| Stale LaunchServices registration | `lsregister -f` fixed the path but widget still didn't appear |
| `pluginkit -a` manual registration | Returned exit 0 but silently did nothing |
| Missing provisioning profile | Free Apple ID dev signing works without embedded profiles |

---

## 2. containerBackground Is Required (macOS 14+)

### Symptom
Widget registered and appeared in gallery, but rendered with "Please adopt containerBackground API" message, then went white.

### Root Cause
Starting macOS 14 / iOS 17, WidgetKit requires `.containerBackground(for: .widget)` on the widget entry view. Without it, the system shows a placeholder error instead of widget content.

### Fix
In the `StaticConfiguration` closure:
```swift
StaticConfiguration(kind: kind, provider: Provider()) { entry in
    GlassUsageWidgetView(entry: entry)
        .containerBackground(for: .widget) {
            Color.clear
        }
}
```

Using `Color.clear` lets macOS handle the glass/material background natively. The old `ZStack { ContainerRelativeShape().fill(.ultraThinMaterial) }` approach must be removed — it conflicts with the system's background management.

---

## 3. Sandbox Breaks homeDirectoryForCurrentUser

### Symptom
Widget showed "Claude CLI not installed" despite Claude CLI being installed at `~/.claude`.

### Root Cause
In a sandboxed extension, `FileManager.default.homeDirectoryForCurrentUser` and `NSHomeDirectory()` return the **container path** (`~/Library/Containers/com.jameslopez.GlassUsage.widget/Data`), not `/Users/jeeves`. The widget was checking for `.claude` inside its container.

### Fix
Added `realHomeDirectory()` helper in `Shared/APIClient.swift` that uses `getpwuid(getuid())` to read the real home path from the system passwd database:
```swift
func realHomeDirectory() -> URL {
    if let pw = getpwuid(getuid()) {
        return URL(fileURLWithPath: String(cString: pw.pointee.pw_dir))
    }
    return FileManager.default.homeDirectoryForCurrentUser
}
```
Replaced all `FileManager.default.homeDirectoryForCurrentUser` calls with `realHomeDirectory()`.

---

## 4. Widget Extension Caches Stale Binaries

### Symptom
Code changes had no effect — widget kept showing old behavior despite successful builds.

### Root Cause
Two issues compounding:
1. **macOS caches the widget extension process.** Rebuilding and re-running the main app (Cmd+R) does NOT restart the widget extension. The old process stays alive with the old binary.
2. **Duplicate source files.** The repo has two copies of every file — outer (`GlassUsage/GlassUsageWidget/`) and inner (`GlassUsage/GlassUsage/GlassUsageWidget/`). Xcode compiles from the **inner** `GlassUsage/GlassUsage/` tree. Edits to the outer files have zero effect.

### Fix
- After rebuilding, kill the widget extension process: `kill $(pgrep -f GlassUsageWidget)`
- Then click/hover the widget to trigger macOS to relaunch it with the new binary
- Always edit files under `GlassUsage/GlassUsage/` (the xcodegen project root), not the outer directory

---

## 5. White Widget Background Is a System Setting

### Symptom
Widget content rendered but with an opaque white background instead of translucent glass.

### Root Cause
Not a code issue. macOS 26 System Settings → Desktop & Dock → Widget style controls this. When set to dim/monochrome, widgets get a white background.

### Fix
System Settings → Desktop & Dock → Widgets → set style to **Full-color**.

Reference: https://talk.macpowerusers.com/t/macos-tahoe-26-widgets-always-have-a-white-background-now/42881
