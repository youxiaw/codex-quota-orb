import SwiftUI

struct OrbView: View {
    @ObservedObject var state: QuotaState
    let onToggle: () -> Void
    let onRefresh: () -> Void
    let onQuit: () -> Void

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            fillColor.opacity(0.95),
                            fillColor.opacity(0.45),
                            Color.white.opacity(0.16)
                        ],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: 82
                    )
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.55), lineWidth: 1.4)
                )
                .shadow(color: fillColor.opacity(0.55), radius: 18, y: 8)

            Circle()
                .trim(from: 0, to: max(0.04, percent / 100))
                .stroke(Color.white.opacity(0.86), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(8)

            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("Codex")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .opacity(0.82)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
        }
        .frame(width: 92, height: 92)
        .contentShape(Circle())
        .onTapGesture(perform: onToggle)
        .contextMenu {
            Button("Refresh", action: onRefresh)
            Divider()
            Button("Quit", action: onQuit)
        }
    }

    private var percent: Double {
        state.snapshot?.mostConstrainedRemainingPercent ?? 0
    }

    private var label: String {
        guard state.snapshot != nil else {
            return "--"
        }
        return "\(Int(percent.rounded()))%"
    }

    private var fillColor: Color {
        switch percent {
        case 40...:
            return Color(red: 0.16, green: 0.61, blue: 0.95)
        case 20..<40:
            return Color(red: 0.95, green: 0.62, blue: 0.28)
        case 0..<20:
            return Color(red: 0.96, green: 0.24, blue: 0.33)
        default:
            return Color(red: 0.48, green: 0.54, blue: 0.62)
        }
    }
}
