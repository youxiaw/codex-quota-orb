import SwiftUI

struct DetailPanelView: View {
    @ObservedObject var state: QuotaState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Codex Quota")
                        .font(.system(size: 23, weight: .heavy, design: .rounded))
                    Text(statusText)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("Auto refresh every 60s")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(.secondary.opacity(0.78))
                }
                Spacer()
                Button("Refresh") {
                    state.refresh()
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 12) {
                quotaCard(title: "5h", window: state.snapshot?.fiveHour)
                quotaCard(title: "Week", window: state.snapshot?.weekly)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Recent trend")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                QuotaLineChartView(samples: state.history)
                    .frame(height: 172)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(width: 390, height: 420)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.09, green: 0.11, blue: 0.16).opacity(0.84),
                        Color(red: 0.04, green: 0.06, blue: 0.1).opacity(0.76)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(.ultraThinMaterial.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.24), radius: 24, y: 14)
    }

    private func quotaCard(title: String, window: QuotaWindow?) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(0.9)
                    .foregroundStyle(.secondary)
                Spacer()
                Circle()
                    .fill(cardAccent(window).opacity(0.9))
                    .frame(width: 8, height: 8)
            }
            Text(window.map { "\(Int($0.remainingPercent.rounded()))%" } ?? "--")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .monospacedDigit()
            Text(resetLabel(window?.resetAt))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.15),
                    cardAccent(window).opacity(0.09),
                    Color.black.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
        )
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

    private func resetLabel(_ date: Date?) -> String {
        guard let date else {
            return "No reset time"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
