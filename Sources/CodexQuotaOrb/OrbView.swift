import SwiftUI

struct OrbView: View {
    @ObservedObject var state: QuotaState
    let onToggle: () -> Void
    let onRefresh: () -> Void
    let onQuit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ringRotation = 0.0
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            glow
                .scaleEffect(glowPulse && !reduceMotion ? 1.035 : 1.0)
                .opacity(isRefreshing ? 0.74 : (glowPulse && !reduceMotion ? 0.54 : 0.42))

            orbBase

            StaticWaveFillShape(level: max(0.08, min(0.92, percent / 100)))
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.36),
                            accent.opacity(0.18)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(Circle().inset(by: 11))

            sparkleDots

            primaryRing
                .rotationEffect(.degrees(ringRotation + (isRefreshing ? 22 : 0)))

            secondaryRing
                .rotationEffect(.degrees(-ringRotation * 0.42 + (isRefreshing ? -16 : 0)))

            quotaRing

            topHighlight

            if isRefreshing {
                refreshPulse
            }

            labelStack
        }
        .frame(width: 92, height: 92)
        .clipShape(Circle())
        .contentShape(Circle())
        .onTapGesture(perform: onToggle)
        .task(id: reduceMotion) {
            await runLowPowerMotion()
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: isRefreshing)
        .contextMenu {
            Button("Refresh", action: onRefresh)
            Divider()
            Button("Quit", action: onQuit)
        }
    }

    private var glow: some View {
        Circle()
            .inset(by: 5)
            .fill(
                RadialGradient(
                    colors: [
                        accent.opacity(0.2),
                        accent.opacity(0.07),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: 45
                )
            )
    }

    private var orbBase: some View {
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
                                accent.opacity(0.52),
                                Color(red: 0.44, green: 0.62, blue: 0.72).opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: accent.opacity(0.14), radius: 7, y: 4)
            .shadow(color: Color(red: 0.18, green: 0.28, blue: 0.36).opacity(0.08), radius: 5, y: 4)
    }

    private var sparkleDots: some View {
        ZStack {
            sparkle(width: 4, x: -18, y: -12, opacity: 0.72)
            sparkle(width: 3, x: 20, y: -4, opacity: 0.5)
            sparkle(width: 2.5, x: 8, y: 19, opacity: 0.44)
            sparkle(width: 2, x: -23, y: 16, opacity: 0.36)
        }
    }

    private func sparkle(width: CGFloat, x: CGFloat, y: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(Color.white.opacity(opacity))
            .frame(width: width, height: width)
            .shadow(color: accent.opacity(0.2), radius: 2)
            .offset(x: x, y: y)
    }

    private var primaryRing: some View {
        Circle()
            .trim(from: 0.05, to: 0.82)
            .stroke(
                AngularGradient(
                    colors: [
                        accent.opacity(0.08),
                        accent.opacity(0.86),
                        Color.white.opacity(0.98),
                        accent.opacity(0.16)
                    ],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 4.8, lineCap: .round)
            )
            .padding(6)
    }

    private var secondaryRing: some View {
        Circle()
            .stroke(
                accent.opacity(0.5),
                style: StrokeStyle(
                    lineWidth: 1.7,
                    lineCap: .round,
                    dash: [6, 11]
                )
            )
            .padding(18)
    }

    private var quotaRing: some View {
        Circle()
            .trim(from: 0, to: max(0.04, percent / 100))
            .stroke(
                AngularGradient(
                    colors: [
                        accent.opacity(0.14),
                        accent,
                        Color.white.opacity(0.96),
                        accent.opacity(0.14)
                    ],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 6.1, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .padding(10)
    }

    private var topHighlight: some View {
        Circle()
            .fill(Color.white.opacity(0.9))
            .frame(width: 25, height: 11)
            .blur(radius: 2)
            .rotationEffect(.degrees(-28))
            .offset(x: -17, y: -26)
    }

    private var refreshPulse: some View {
        Circle()
            .stroke(accent.opacity(0.26), lineWidth: 2)
            .scaleEffect(1.08)
            .padding(4)
    }

    private var labelStack: some View {
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

    private func runLowPowerMotion() async {
        guard !reduceMotion else {
            return
        }

        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            if Task.isCancelled {
                return
            }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.9)) {
                    ringRotation += 10
                    glowPulse.toggle()
                }
            }
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

    private var isRefreshing: Bool {
        if case .refreshing = state.status {
            return true
        }
        return false
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

private struct StaticWaveFillShape: Shape {
    let level: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let baseY = rect.maxY - rect.height * CGFloat(level)
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: baseY))

        path.addCurve(
            to: CGPoint(x: rect.maxX, y: baseY),
            control1: CGPoint(x: rect.width * 0.28, y: baseY - rect.height * 0.055),
            control2: CGPoint(x: rect.width * 0.64, y: baseY + rect.height * 0.06)
        )

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
