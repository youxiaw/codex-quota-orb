import SwiftUI

struct DetailPanelView: View {
    @ObservedObject var state: QuotaState

    var body: some View {
        ZStack(alignment: .topLeading) {
            panelBackground

            VStack(alignment: .leading, spacing: 18) {
                header

                HStack(spacing: 14) {
                    quotaCard(title: "5h", subtitle: "Fast window", window: state.snapshot?.fiveHour)
                    quotaCard(title: "Week", subtitle: "Weekly cap", window: state.snapshot?.weekly)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Trend")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(ink)
                        Text("\(state.history.count) samples")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(ink.opacity(0.48))
                        Spacer()
                        rangePicker
                    }

                    QuotaLineChartView(samples: state.history)
                        .frame(height: 214)
                }
            }
            .padding(22)
        }
        .frame(width: 472, height: 536)
    }

    private var rangePicker: some View {
        Picker("Trend range", selection: Binding(
            get: { state.trendRange },
            set: { state.setTrendRange($0) }
        )) {
            ForEach(QuotaTrendRange.allCases) { range in
                Text(range.title).tag(range)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .frame(width: 178)
        .controlSize(.small)
        .help("Change trend time range")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(activeAccent.opacity(0.18))
                    .frame(width: 48, height: 48)
                    .blur(radius: 8)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white,
                                activeAccent.opacity(0.34),
                                Color(red: 0.86, green: 0.94, blue: 0.98)
                            ],
                            center: .topLeading,
                            startRadius: 1,
                            endRadius: 34
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.95), lineWidth: 1.2))
                    .shadow(color: activeAccent.opacity(0.24), radius: 14, y: 6)
                Text("Q")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(activeAccent)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text("Codex Quota")
                        .font(.system(size: 25, weight: .black, design: .rounded))
                        .foregroundStyle(ink)
                    statusPill
                }
                Text(statusText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(ink.opacity(0.58))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 7) {
                    Circle()
                        .fill(activeAccent)
                        .frame(width: 6, height: 6)
                    Text("Auto refresh every 60s")
                        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                        .tracking(0.35)
                        .foregroundStyle(ink.opacity(0.48))
                }
            }

            Spacer(minLength: 8)

            Button {
                state.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .foregroundStyle(activeAccent)
            .background(
                Circle()
                    .fill(Color.white.opacity(0.82))
                    .overlay(Circle().strokeBorder(Color.white, lineWidth: 1))
            )
            .shadow(color: Color.black.opacity(0.09), radius: 10, y: 5)
            .help("Refresh now")
        }
    }

    private var statusPill: some View {
        Text(statusPillText)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .tracking(0.45)
            .foregroundStyle(activeAccent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(activeAccent.opacity(0.12), in: Capsule())
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.99, green: 1.0, blue: 1.0),
                        Color(red: 0.92, green: 0.97, blue: 0.99),
                        Color(red: 0.88, green: 0.93, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RadialGradient(
                    colors: [
                        activeAccent.opacity(0.16),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 10,
                    endRadius: 280
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.96), lineWidth: 1.2)
            )
            .shadow(color: Color(red: 0.12, green: 0.23, blue: 0.32).opacity(0.18), radius: 28, y: 18)
    }

    private func quotaCard(title: String, subtitle: String, window: QuotaWindow?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(0.9)
                    .foregroundStyle(ink.opacity(0.48))
                Spacer()
                Circle()
                    .fill(cardAccent(window))
                    .frame(width: 9, height: 9)
                    .shadow(color: cardAccent(window).opacity(0.38), radius: 6)
            }

            Text(window.map { "\(Int($0.remainingPercent.rounded()))%" } ?? "--")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(ink)
                .minimumScaleFactor(0.8)

            VStack(alignment: .leading, spacing: 3) {
                Text(subtitle)
                    .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(ink.opacity(0.42))
                Text(resetLabel(window?.resetAt))
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(ink.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 134, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.96),
                            cardAccent(window).opacity(0.08),
                            Color(red: 0.93, green: 0.97, blue: 0.99)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.96), lineWidth: 1)
        )
        .shadow(color: Color(red: 0.12, green: 0.2, blue: 0.28).opacity(0.1), radius: 16, y: 8)
    }

    private func cardAccent(_ window: QuotaWindow?) -> Color {
        guard let percent = window?.remainingPercent else {
            return Color(red: 0.47, green: 0.56, blue: 0.66)
        }
        switch percent {
        case 40...:
            return Color(red: 0.0, green: 0.58, blue: 0.72)
        case 20..<40:
            return Color(red: 0.92, green: 0.48, blue: 0.14)
        default:
            return Color(red: 0.9, green: 0.16, blue: 0.26)
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

    private var statusPillText: String {
        switch state.status {
        case .refreshing:
            return "SYNC"
        case .stale:
            return "STALE"
        case .unavailable:
            return "OFF"
        case .idle:
            return "WAIT"
        case .ready:
            return "LIVE"
        }
    }

    private var activeAccent: Color {
        cardAccent(state.snapshot?.fiveHour ?? state.snapshot?.weekly)
    }

    private var ink: Color {
        Color(red: 0.08, green: 0.12, blue: 0.18)
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
