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
                            accent.opacity(0.18),
                            Color.white.opacity(0.05),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 78
                    )
                )
                .blur(radius: 8)
                .offset(x: -5, y: -6)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.91, green: 0.97, blue: 1.0),
                            Color(red: 0.74, green: 0.9, blue: 0.96)
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
                                    Color.white.opacity(0.98),
                                    accent.opacity(0.5),
                                    Color(red: 0.44, green: 0.62, blue: 0.72).opacity(0.22)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: accent.opacity(0.2), radius: 14, y: 6)
                .shadow(color: Color(red: 0.18, green: 0.28, blue: 0.36).opacity(0.13), radius: 12, y: 8)

            WaterFillShape(level: max(0.08, min(0.92, percent / 100)))
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.34),
                            accent.opacity(0.2)
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
                            Color.white.opacity(0.96),
                            accent.opacity(0.15)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 5.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(7)

            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
                .padding(18)

            Circle()
                .fill(Color.white.opacity(0.86))
                .frame(width: 24, height: 11)
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
            .foregroundStyle(ink)
            .shadow(color: .white.opacity(0.55), radius: 1, y: -1)
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
            return Color(red: 0.0, green: 0.58, blue: 0.72)
        case 20..<40:
            return Color(red: 0.92, green: 0.48, blue: 0.14)
        case 0..<20:
            return Color(red: 0.9, green: 0.16, blue: 0.26)
        default:
            return Color(red: 0.47, green: 0.56, blue: 0.66)
        }
    }

    private var ink: Color {
        Color(red: 0.08, green: 0.12, blue: 0.18)
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
