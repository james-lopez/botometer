import SwiftUI

struct ContentView: View {
    @StateObject private var parser = UsageParser()

    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Glass background
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "waveform.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.purple.gradient)
                    Text("Claude Usage")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Circle()
                        .fill(.green)
                        .frame(width: 7, height: 7)
                }

                Divider().opacity(0.3)

                // Today section
                VStack(alignment: .leading, spacing: 6) {
                    Label("TODAY", systemImage: "sun.max.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        StatPill(
                            value: formatTokens(parser.stats.todayInputTokens + parser.stats.todayOutputTokens),
                            label: "tokens",
                            color: .blue
                        )
                        StatPill(
                            value: "\(parser.stats.todayAPICalls)",
                            label: "calls",
                            color: .purple
                        )
                    }
                }

                Divider().opacity(0.3)

                // All time section
                VStack(alignment: .leading, spacing: 6) {
                    Label("ALL TIME", systemImage: "clock.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        MiniStat(label: "Input", value: formatTokens(parser.stats.totalInputTokens), icon: "arrow.down.circle")
                        MiniStat(label: "Output", value: formatTokens(parser.stats.totalOutputTokens), icon: "arrow.up.circle")
                        MiniStat(label: "Cache R", value: formatTokens(parser.stats.totalCacheRead), icon: "bolt.circle")
                        MiniStat(label: "Cache W", value: formatTokens(parser.stats.totalCacheWrite), icon: "square.and.pencil.circle")
                    }
                }

                Divider().opacity(0.3)

                // Cost estimate
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundStyle(.green.gradient)
                    Text("Est. cost")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "$%.4f", parser.stats.estimatedCostUSD))
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.semibold)
                }

                // Footer
                HStack {
                    Text("\(parser.stats.sessionCount) sessions")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("Updated \(parser.lastUpdated, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
        }
        .frame(width: 280)
        .onAppear { parser.refresh() }
        .onReceive(timer) { _ in parser.refresh() }
    }

    func formatTokens(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000 { return String(format: "%.1fK", Double(n) / 1_000) }
        return "\(n)"
    }
}

struct StatPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(color.gradient)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.1), in: Capsule())
    }
}

struct MiniStat: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ContentView()
        .padding()
        .background(.black.opacity(0.3))
}
