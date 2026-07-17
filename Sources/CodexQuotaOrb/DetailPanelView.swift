import SwiftUI

struct DetailPanelView: View {
    @ObservedObject var state: QuotaState

    var body: some View {
        ZStack(alignment: .topLeading) {
            panelBackground

            VStack(alignment: .leading, spacing: 16) {
                header

                HStack(spacing: 12) {
                    quotaCard(title: "5h", subtitle: "Fast window", window: state.snapshot?.fiveHour)
                    quotaCard(title: "Week", subtitle: "Weekly cap", window: state.snapshot?.weekly)
                }

                VStack(alignment: .leading, spacing: 9) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Trend")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                        Text("\(state.history.count) samples")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Hover for details")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary.opacity(0.9))
                    }

                    QuotaLineChartView(samples: state.history)
                        .frame(height: 184)
                }

                Spacer(minLength: 0)
            }
            .padding(18)
        }
        .frame(width: 414, height: 438)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(activeAccent.opacity(0.2))
                    .frame(width: 42, height: 42)
                    .blur(radius: 8)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.88),
                                activeAccent.opacity(0.92),
                                Color(red: 0.05, green: 0.07, blue: 0.11)
                            ],
                            center: .topLeading,
                            startRadius: 1,
                            endRadius: 30
                        )
                    )
                    .frame(width: 34, height: 34)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.32), lineWidth: 1))
                    .shadow(color: activeAccent.opacity(0.4), radius: 12, y: 5)
                Text("Q")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.04, green: 0.06, blue: 0.09))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Codex Quota")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(statusText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 6) {
                    Circle()
                        .fill(activeAccent)
                        .frame(width: 6, height: 6)
                    Text("Auto refresh every 60s")
                        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                        .tracking(0.45)
                        .foregroundStyle(.white.opacity(0.62))
                }
            }

            Spacer()

            Button {
                state.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.9))
            .background(
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.16), lineWidth: 1))
            )
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            .help("Refresh now")
        }
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.105, green: 0.13, blue: 0.18).opacity(0.95),
                        Color(red: 0.045, green: 0.055, blue: 0.085).opacity(0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RadialGradient(
                    colors: [
                        activeAccent.opacity(0.28),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 10,
                    endRadius: 260
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            )
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.035),
                        Color.black.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.32),
                                activeAccent.opacity(0.28),
                                Color.black.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: activeAccent.opacity(0.13), radius: 30, y: 15)
            .shadow(color: .black.opacity(0.36), radius: 32, y: 18)
    }

    private func quotaCard(title: String, subtitle: String, window: QuotaWindow?) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(0.9)
                    .foregroundStyle(.white.opacity(0.56))
                Spacer()
                Circle()
                    .fill(cardAccent(window))
                    .frame(width: 9, height: 9)
                    .shadow(color: cardAccent(window).opacity(0.65), radius: 7)
            }
            Text(window.map { "\(Int($0.remainingPercent.rounded()))%" } ?? "--")
                .font(.system(size: 35, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(subtitle)
                    .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.44))
                Text(resetLabel(window?.resetAt))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.16),
                                cardAccent(window).opacity(0.12),
                                Color.black.opacity(0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                cardAccent(window).opacity(0.22),
                                Color.clear
                            ],
                            center: .topTrailing,
                            startRadius: 4,
                            endRadius: 130
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: cardAccent(window).opacity(0.1), radius: 12, y: 8)
    }

    private func cardAccent(_ window: QuotaWindow?) -> Color {
        guard let percent = window?.remainingPercent else {
            return Color(red: 0.54, green: 0.59, blue: 0.67)
        }
        switch percent {
        case 40...:
            return Color(red: 0.05, green: 0.72, blue: 0.86)
        case 20..<40:
            return Color(red: 0.96, green: 0.62, blue: 0.25)
        default:
            return Color(red: 0.96, green: 0.25, blue: 0.36)
        }
    }

    private var statusText: String {
        switch state.status {
        case .idle:
            return "Waiting for first refresh"
        case .refreshing:
            return "Refreshing local Codex runtime..."
        case .ready:
            return "Updated \(state.snapshot.map { resetLabel($0.updatedAt) } ?? "now")"
        case .stale(let message):
            return "Stale: \(message)"
        case .unavailable(let message):
            return "Unavailable: \(message)"
        }
    }

    private var activeAccent: Color {
        cardAccent(state.snapshot?.fiveHour ?? state.snapshot?.weekly)
    }

    private func resetLabel(_ date: Date?) -> String {
        guard let date else {
            return "No reset time"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
