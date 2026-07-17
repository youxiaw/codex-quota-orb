import SwiftUI

struct OrbView: View {
    @ObservedObject var state: QuotaState
    let onToggle: () -> Void
    let onRefresh: () -> Void
    let onQuit: () -> Void

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 45.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let pulse = 1 + CGFloat(sin(time * pulseSpeed)) * 0.025
            let ringSpeed = isRefreshing ? 190.0 : 58.0

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                accent.opacity(0.22),
                                accent.opacity(0.06),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 18,
                            endRadius: 76
                        )
                    )
                    .blur(radius: 10 + CGFloat(abs(sin(time * 1.4))) * 4)
                    .scaleEffect(1.04 + CGFloat(sin(time * 1.15)) * 0.035)

                ForEach(0..<10, id: \.self) { index in
                    Circle()
                        .fill(index.isMultiple(of: 3) ? Color.white.opacity(0.9) : accent.opacity(0.72))
                        .frame(width: particleSize(index), height: particleSize(index))
                        .blur(radius: index.isMultiple(of: 2) ? 0.4 : 0)
                        .offset(particleOffset(index: index, time: time))
                        .opacity(0.38 + 0.32 * abs(sin(time * 1.7 + Double(index))))
                }

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
                    .shadow(color: accent.opacity(0.22), radius: 14, y: 6)
                    .shadow(color: Color(red: 0.18, green: 0.28, blue: 0.36).opacity(0.13), radius: 12, y: 8)

                WaveFillShape(level: max(0.08, min(0.92, percent / 100)), phase: time * (isRefreshing ? 4.8 : 2.0))
                    .fill(
                        LinearGradient(
                            colors: [
                                accent.opacity(0.38),
                                accent.opacity(0.18)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(Circle().inset(by: 11))
                    .blur(radius: 0.15)

                Circle()
                    .trim(from: 0.05, to: 0.82)
                    .stroke(
                        AngularGradient(
                            colors: [
                                accent.opacity(0.06),
                                accent.opacity(0.9),
                                Color.white.opacity(0.98),
                                accent.opacity(0.18)
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 4.8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(time * ringSpeed))
                    .padding(6)

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
                    .rotationEffect(.degrees(-90 - time * (isRefreshing ? 95 : 18)))
                    .padding(10)

                Circle()
                    .stroke(
                        accent.opacity(0.55),
                        style: StrokeStyle(
                            lineWidth: 2,
                            lineCap: .round,
                            dash: [6, 10],
                            dashPhase: CGFloat(time * (isRefreshing ? -34 : -12))
                        )
                    )
                    .rotationEffect(.degrees(-time * (isRefreshing ? 120 : 36)))
                    .padding(18)

                Circle()
                    .stroke(Color.white.opacity(0.82), lineWidth: 1)
                    .padding(22)

                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 25, height: 11)
                    .blur(radius: 2)
                    .rotationEffect(.degrees(-28))
                    .offset(x: -17, y: -26)

                if isRefreshing {
                    Circle()
                        .stroke(accent.opacity(0.3), lineWidth: 2)
                        .scaleEffect(1.08 + CGFloat(sin(time * 7)) * 0.05)
                        .blur(radius: 2)
                        .padding(4)
                }

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
            .scaleEffect(pulse)
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

    private var isRefreshing: Bool {
        if case .refreshing = state.status {
            return true
        }
        return false
    }

    private var pulseSpeed: Double {
        isRefreshing ? 5.2 : 1.8
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

    private func particleSize(_ index: Int) -> CGFloat {
        CGFloat(2 + (index % 3))
    }

    private func particleOffset(index: Int, time: TimeInterval) -> CGSize {
        let seed = Double(index)
        let angle = time * (0.42 + seed * 0.035) + seed * 0.74
        let radius = CGFloat(19 + (index % 5) * 4)
        let drift = CGFloat(sin(time * 0.8 + seed)) * 3
        return CGSize(
            width: CGFloat(cos(angle)) * radius + drift,
            height: CGFloat(sin(angle * 1.12)) * (radius * 0.72)
        )
    }
}

private struct WaveFillShape: Shape {
    let level: Double
    let phase: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let baseY = rect.maxY - rect.height * CGFloat(level)
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: baseY))

        let amplitude = rect.height * 0.045
        let step = max(2, rect.width / 28)
        var x = rect.minX
        while x <= rect.maxX {
            let progress = (x - rect.minX) / rect.width
            let wave = sin(Double(progress) * .pi * 2 + phase) * Double(amplitude)
                + sin(Double(progress) * .pi * 4 + phase * 0.62) * Double(amplitude * 0.45)
            path.addLine(to: CGPoint(x: x, y: baseY + CGFloat(wave)))
            x += step
        }

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
