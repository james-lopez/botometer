import SwiftUI

private let previewUtil = Utilization(
    five_hour: RateLimit(utilization: 42, resets_at: nil),
    seven_day: RateLimit(utilization: 67, resets_at: nil),
    seven_day_opus: RateLimit(utilization: 30, resets_at: nil),
    seven_day_sonnet: nil,
    extra_usage: nil
)
private let previewSession = SessionStats(
    inputTokens: 146, outputTokens: 12756,
    cacheRead: 3215270, cacheWrite: 168329,
    apiCalls: 76, sessionCount: 2
)

#Preview("Widget — Small") {
    SmallView(util: previewUtil, session: previewSession, date: .now)
        .frame(width: 170, height: 170)
        .background(.black.opacity(0.6))
        .preferredColorScheme(.dark)
}

#Preview("Widget — Medium") {
    MediumView(util: previewUtil, session: previewSession, date: .now)
        .frame(width: 364, height: 170)
        .background(.black.opacity(0.6))
        .preferredColorScheme(.dark)
}

#Preview("Widget — Large") {
    LargeView(util: previewUtil, session: previewSession, date: .now)
        .frame(width: 364, height: 382)
        .background(.black.opacity(0.6))
        .preferredColorScheme(.dark)
}
