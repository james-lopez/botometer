import Foundation

struct UsageStats {
    var totalInputTokens: Int = 0
    var totalOutputTokens: Int = 0
    var totalCacheRead: Int = 0
    var totalCacheWrite: Int = 0
    var totalAPICalls: Int = 0
    var sessionCount: Int = 0
    var todayInputTokens: Int = 0
    var todayOutputTokens: Int = 0
    var todayAPICalls: Int = 0

    var estimatedCostUSD: Double {
        // Opus 4.6 pricing (per million tokens)
        let inputCost = Double(totalInputTokens) / 1_000_000 * 15.0
        let outputCost = Double(totalOutputTokens) / 1_000_000 * 75.0
        let cacheReadCost = Double(totalCacheRead) / 1_000_000 * 1.50
        let cacheWriteCost = Double(totalCacheWrite) / 1_000_000 * 18.75
        return inputCost + outputCost + cacheReadCost + cacheWriteCost
    }

    var totalTokens: Int {
        totalInputTokens + totalOutputTokens
    }
}

struct MessageUsage: Codable {
    let input_tokens: Int?
    let output_tokens: Int?
    let cache_read_input_tokens: Int?
    let cache_creation_input_tokens: Int?
}

struct AssistantMessage: Codable {
    let usage: MessageUsage?
}

struct SessionEntry: Codable {
    let type: String?
    let message: AssistantMessage?
    let timestamp: String?
}

class UsageParser: ObservableObject {
    @Published var stats = UsageStats()
    @Published var lastUpdated = Date()

    private let claudeDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/projects")

    // Synchronous version for WidgetKit timeline provider
    func parseSync() -> UsageStats {
        parse()
    }

    func refresh() {
        Task.detached(priority: .background) {
            let result = self.parse()
            await MainActor.run {
                self.stats = result
                self.lastUpdated = Date()
            }
        }
    }

    private func parse() -> UsageStats {
        var stats = UsageStats()
        let fm = FileManager.default
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let projectDirs = try? fm.contentsOfDirectory(
            at: claudeDir,
            includingPropertiesForKeys: nil
        ) else { return stats }

        for projectDir in projectDirs {
            guard let files = try? fm.contentsOfDirectory(
                at: projectDir,
                includingPropertiesForKeys: nil
            ) else { continue }

            let jsonlFiles = files.filter { $0.pathExtension == "jsonl" }
            stats.sessionCount += jsonlFiles.count

            for file in jsonlFiles {
                guard let content = try? String(contentsOf: file, encoding: .utf8) else { continue }

                for line in content.components(separatedBy: "\n") {
                    guard !line.isEmpty,
                          let data = line.data(using: .utf8),
                          let entry = try? JSONDecoder().decode(SessionEntry.self, from: data),
                          entry.type == "assistant",
                          let usage = entry.message?.usage else { continue }

                    let input = usage.input_tokens ?? 0
                    let output = usage.output_tokens ?? 0
                    let cacheRead = usage.cache_read_input_tokens ?? 0
                    let cacheWrite = usage.cache_creation_input_tokens ?? 0

                    stats.totalInputTokens += input
                    stats.totalOutputTokens += output
                    stats.totalCacheRead += cacheRead
                    stats.totalCacheWrite += cacheWrite
                    stats.totalAPICalls += 1

                    // Today's stats
                    if let timestamp = entry.timestamp,
                       let date = ISO8601DateFormatter().date(from: timestamp),
                       calendar.startOfDay(for: date) == today {
                        stats.todayInputTokens += input
                        stats.todayOutputTokens += output
                        stats.todayAPICalls += 1
                    }
                }
            }
        }

        return stats
    }
}
