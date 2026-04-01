import WidgetKit
import SwiftUI

struct UsageEntry: TimelineEntry {
    let date: Date
    let stats: UsageStats
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> UsageEntry {
        UsageEntry(date: Date(), stats: UsageStats())
    }

    func getSnapshot(in context: Context, completion: @escaping (UsageEntry) -> Void) {
        let parser = UsageParser()
        let stats = parser.parseSync()
        completion(UsageEntry(date: Date(), stats: stats))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> Void) {
        let parser = UsageParser()
        let stats = parser.parseSync()
        let entry = UsageEntry(date: Date(), stats: stats)
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct GlassUsageWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(.ultraThinMaterial)

            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Image(systemName: "waveform.circle.fill")
                        .foregroundStyle(.purple.gradient)
                    Text("Claude")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                }

                Divider().opacity(0.3)

                if family == .systemSmall {
                    SmallWidgetView(stats: entry.stats)
                } else {
                    MediumWidgetView(stats: entry.stats)
                }

                Spacer()

                Text("Updated \(entry.date, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
        }
    }
}

struct SmallWidgetView: View {
    let stats: UsageStats

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            statRow(label: "Today", value: formatTokens(stats.todayInputTokens + stats.todayOutputTokens), color: .blue)
            statRow(label: "Calls", value: "\(stats.todayAPICalls)", color: .purple)
            statRow(label: "Cost", value: String(format: "$%.3f", stats.estimatedCostUSD), color: .green)
        }
    }

    func statRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(color.gradient)
        }
    }
}

struct MediumWidgetView: View {
    let stats: UsageStats

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TODAY")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Text(formatTokens(stats.todayInputTokens + stats.todayOutputTokens))
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(.blue.gradient)
                Text("tokens")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("\(stats.todayAPICalls) calls")
                    .font(.caption)
                    .foregroundStyle(.purple.gradient)
            }

            Divider().opacity(0.3)

            VStack(alignment: .leading, spacing: 4) {
                Text("ALL TIME")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Text(formatTokens(stats.totalTokens))
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(.purple.gradient)
                Text("tokens")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text(String(format: "~$%.3f", stats.estimatedCostUSD))
                    .font(.caption)
                    .foregroundStyle(.green.gradient)
            }
        }
    }
}

func formatTokens(_ n: Int) -> String {
    if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
    if n >= 1_000 { return String(format: "%.1fK", Double(n) / 1_000) }
    return "\(n)"
}

@main
struct GlassUsageWidget: Widget {
    let kind: String = "GlassUsageWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            GlassUsageWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Claude Usage")
        .description("Live Claude CLI token usage and cost.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    GlassUsageWidget()
} timeline: {
    UsageEntry(date: .now, stats: UsageStats())
}
