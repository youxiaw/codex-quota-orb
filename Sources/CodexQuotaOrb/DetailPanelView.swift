import SwiftUI

struct DetailPanelView: View {
    @ObservedObject var state: QuotaState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Codex Quota")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text(statusText)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
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
                    .frame(height: 150)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(width: 390, height: 420)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.24), radius: 24, y: 14)
    }

    private func quotaCard(title: String, window: QuotaWindow?) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            Text(window.map { "\(Int($0.remainingPercent.rounded()))%" } ?? "--")
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text(resetLabel(window?.resetAt))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
