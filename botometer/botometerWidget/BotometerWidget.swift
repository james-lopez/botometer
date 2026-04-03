import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> UsageEntry {
        UsageEntry(date: Date(), state: .loading)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (UsageEntry) -> Void) {
        Task {
            let entry = await buildEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<UsageEntry>) -> Void) {
        Task {
            let entry = await buildEntry()
            let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(next))
            completion(timeline)
        }
    }

    private func buildEntry() async -> UsageEntry {
        let claudeDir = realHomeDirectory().appendingPathComponent(".claude")
        guard FileManager.default.fileExists(atPath: claudeDir.path) else {
            return UsageEntry(date: Date(), state: .notInstalled)
        }

        let creds: ClaudeCredentials
        do {
            creds = try readClaudeCredentials()
        } catch {
            return UsageEntry(date: Date(), state: .notLoggedIn)
        }

        let session = parseLocalSessions()

        do {
            let utilization = try await fetchUtilization(token: creds.accessToken)
            return UsageEntry(date: Date(), state: .loaded(utilization: utilization, session: session))
        } catch AuthError.tokenExpired {
            return UsageEntry(date: Date(), state: .tokenExpired)
        } catch AuthError.networkError("429") {
            return UsageEntry(date: Date(), state: .rateLimited)
        } catch {
            return UsageEntry(date: Date(), state: .apiError(error.localizedDescription))
        }
    }
}

// MARK: - Widget Config

@main
struct BotometerWidget: Widget {
    let kind = "BotOMeterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            GlassUsageWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("bot-o-meter")
        .description("Claude CLI usage limits and token stats.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}
