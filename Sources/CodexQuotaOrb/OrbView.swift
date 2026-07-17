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
                            Color.white.opacity(0.24),
                            Color.white.opacity(0.04),
                            Color.black.opacity(0.3)
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 78
                    )
                )
                .blur(radius: 10)
                .offset(x: -7, y: -8)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.18, green: 0.22, blue: 0.29),
                            Color(red: 0.08, green: 0.1, blue: 0.15),
                            Color(red: 0.02, green: 0.03, blue: 0.06)
                        ],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 88
                    )
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.72),
                                    accent.opacity(0.38),
                                    Color.black.opacity(0.22)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: accent.opacity(0.34), radius: 22, y: 8)
                .shadow(color: .black.opacity(0.34), radius: 14, y: 10)

            WaterFillShape(level: max(0.08, min(0.92, percent / 100)))
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.78),
                            accent.opacity(0.38)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(Circle().inset(by: 11))
                .blur(radius: 0.2)

            Circle()
                .trim(from: 0, to: max(0.04, percent / 100))
                .stroke(
                    AngularGradient(
                        colors: [
                            accent.opacity(0.15),
                            accent,
                            Color.white.opacity(0.88),
                            accent.opacity(0.15)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 5.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(7)

            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                .padding(18)

            Circle()
                .fill(Color.white.opacity(0.34))
                .frame(width: 22, height: 10)
                .blur(radius: 2)
                .rotationEffect(.degrees(-28))
                .offset(x: -17, y: -26)

            VStack(spacing: 1) {
                Text(label)
                    .font(.system(size: 21, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                Text(statusLabel)
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .opacity(0.8)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.38), radius: 3, y: 1)
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

    private var statusLabel: String {
        switch state.status {
        case .refreshing:
            return "SYNC"
        case .stale:
            return "STALE"
        case .unavailable:
            return "OFF"
        default:
            return "CODEX"
        }
    }

    private var accent: Color {
        switch percent {
        case 40...:
            return Color(red: 0.05, green: 0.72, blue: 0.86)
        case 20..<40:
            return Color(red: 0.96, green: 0.62, blue: 0.25)
        case 0..<20:
            return Color(red: 0.96, green: 0.25, blue: 0.36)
        default:
            return Color(red: 0.53, green: 0.59, blue: 0.68)
        }
    }
}

private struct WaterFillShape: Shape {
    let level: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let baseY = rect.maxY - rect.height * CGFloat(level)
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: baseY))

        let controlY = baseY - rect.height * 0.06
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: baseY),
            control1: CGPoint(x: rect.width * 0.28, y: controlY),
            control2: CGPoint(x: rect.width * 0.64, y: baseY + rect.height * 0.07)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
