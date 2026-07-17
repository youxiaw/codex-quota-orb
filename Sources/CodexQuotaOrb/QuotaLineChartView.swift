import SwiftUI

struct QuotaLineChartView: View {
    let samples: [QuotaSnapshot]
    @State private var hoverLocation: CGPoint?

    private let plotInsets = EdgeInsets(top: 26, leading: 38, bottom: 30, trailing: 18)

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                chartBackground

                let rect = plotRect(in: proxy.size)

                grid(in: rect)
                    .stroke(Color(red: 0.13, green: 0.22, blue: 0.32).opacity(0.1), lineWidth: 1)

                axisLabels(in: proxy.size)

                if samples.isEmpty {
                    emptyState
                } else {
                    areaPath(in: rect, series: weeklySeries)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.58, blue: 0.72).opacity(0.18),
                                    Color(red: 0.0, green: 0.58, blue: 0.72).opacity(0.04),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    areaPath(in: rect, series: fiveHourSeries)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.92, green: 0.48, blue: 0.14).opacity(0.16),
                                    Color(red: 0.92, green: 0.48, blue: 0.14).opacity(0.035),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    linePath(in: rect, series: weeklySeries)
                        .stroke(Color(red: 0.0, green: 0.58, blue: 0.72).opacity(0.16), style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
                        .blur(radius: 5)
                    linePath(in: rect, series: weeklySeries)
                        .stroke(Color(red: 0.0, green: 0.58, blue: 0.72), style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round))

                    linePath(in: rect, series: fiveHourSeries)
                        .stroke(Color(red: 0.92, green: 0.48, blue: 0.14).opacity(0.15), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                        .blur(radius: 4)
                    linePath(in: rect, series: fiveHourSeries)
                        .stroke(Color(red: 0.92, green: 0.48, blue: 0.14), style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))

                    currentMarkers(in: rect)
                }

                legend

                if let hover = hoverLocation,
                   let point = nearestSample(to: hover, in: rect) {
                    hoverOverlay(point, in: rect)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    hoverLocation = location
                case .ended:
                    hoverLocation = nil
                }
            }
        }
    }

    private var chartBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.98),
                        Color(red: 0.93, green: 0.97, blue: 0.99)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RadialGradient(
                    colors: [
                        Color(red: 0.0, green: 0.58, blue: 0.72).opacity(0.12),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 8,
                    endRadius: 210
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.95), lineWidth: 1)
            )
            .shadow(color: Color(red: 0.12, green: 0.2, blue: 0.28).opacity(0.09), radius: 16, y: 8)
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Text("Waiting for quota samples")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
            Text("The curve appears after the first successful refresh")
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(Color(red: 0.08, green: 0.12, blue: 0.18).opacity(0.72))
    }

    private var weeklySeries: [SeriesPoint] {
        samples.enumerated().compactMap { index, sample in
            sample.weekly.map { SeriesPoint(index: index, value: $0.remainingPercent) }
        }
    }

    private var fiveHourSeries: [SeriesPoint] {
        samples.enumerated().compactMap { index, sample in
            sample.fiveHour.map { SeriesPoint(index: index, value: $0.remainingPercent) }
        }
    }

    private var legend: some View {
        VStack {
            HStack(spacing: 10) {
                legendItem(color: Color(red: 0.0, green: 0.58, blue: 0.72), text: "Week")
                legendItem(color: Color(red: 0.92, green: 0.48, blue: 0.14), text: "5h")
                Spacer()
            }
            Spacer()
        }
        .padding(.top, 6)
        .padding(.leading, 42)
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Capsule()
                .fill(color.opacity(0.9))
                .frame(width: 14, height: 3)
            Text(text)
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.08, green: 0.12, blue: 0.18).opacity(0.55))
        }
    }

    private func axisLabels(in size: CGSize) -> some View {
        let rect = plotRect(in: size)
        return ZStack(alignment: .topLeading) {
            yLabel("100", at: rect.minY - 7)
            yLabel("50", at: rect.midY - 7)
            yLabel("0", at: rect.maxY - 11)

            if let first = samples.first?.updatedAt {
                xLabel(timeLabel(first))
                    .position(x: rect.minX + 18, y: rect.maxY + 17)
            }
            if let last = samples.last?.updatedAt {
                xLabel(timeLabel(last))
                    .position(x: rect.maxX - 20, y: rect.maxY + 17)
            }
        }
    }

    private func yLabel(_ text: String, at y: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 9.5, weight: .bold, design: .rounded))
            .foregroundStyle(Color(red: 0.08, green: 0.12, blue: 0.18).opacity(0.48))
            .frame(width: 26, alignment: .trailing)
            .position(x: 18, y: y + 7)
    }

    private func xLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9.5, weight: .bold, design: .rounded))
            .foregroundStyle(Color(red: 0.08, green: 0.12, blue: 0.18).opacity(0.48))
    }

    private func hoverOverlay(_ samplePoint: SamplePoint, in rect: CGRect) -> some View {
        let x = xPosition(for: samplePoint.index, count: max(samples.count, 2), in: rect)
        return ZStack(alignment: .topLeading) {
            Path { path in
                path.move(to: CGPoint(x: x, y: rect.minY))
                path.addLine(to: CGPoint(x: x, y: rect.maxY))
            }
            .stroke(Color(red: 0.08, green: 0.12, blue: 0.18).opacity(0.24), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

            if let weekly = samplePoint.snapshot.weekly?.remainingPercent {
                dot(at: CGPoint(x: x, y: yPosition(for: weekly, in: rect)), color: Color(red: 0.0, green: 0.58, blue: 0.72))
            }
            if let fiveHour = samplePoint.snapshot.fiveHour?.remainingPercent {
                dot(at: CGPoint(x: x, y: yPosition(for: fiveHour, in: rect)), color: Color(red: 0.92, green: 0.48, blue: 0.14))
            }

            tooltip(samplePoint.snapshot)
                .position(
                    x: min(max(x + 54, rect.minX + 64), rect.maxX - 64),
                    y: rect.minY + 34
                )
        }
    }

    private func currentMarkers(in rect: CGRect) -> some View {
        ZStack {
            if let point = weeklySeries.last {
                marker(point, in: rect, color: Color(red: 0.0, green: 0.58, blue: 0.72))
            }
            if let point = fiveHourSeries.last {
                marker(point, in: rect, color: Color(red: 0.92, green: 0.48, blue: 0.14))
            }
        }
    }

    private func marker(_ point: SeriesPoint, in rect: CGRect, color: Color) -> some View {
        let location = CGPoint(
            x: xPosition(for: point.index, count: max(samples.count, 2), in: rect),
            y: yPosition(for: point.value, in: rect)
        )
        return ZStack {
            Circle()
                .fill(color.opacity(0.18))
                .frame(width: 20, height: 20)
                .blur(radius: 2)
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 1))
        }
        .position(location)
    }

    private func dot(at point: CGPoint, color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
            .position(point)
    }

    private func tooltip(_ snapshot: QuotaSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(fullTimeLabel(snapshot.updatedAt))
                .font(.system(size: 10, weight: .heavy, design: .rounded))
            Text("Week \(percentLabel(snapshot.weekly?.remainingPercent))")
                .foregroundStyle(Color(red: 0.0, green: 0.58, blue: 0.72))
            Text("5h \(percentLabel(snapshot.fiveHour?.remainingPercent))")
                .foregroundStyle(Color(red: 0.92, green: 0.48, blue: 0.14))
        }
        .font(.system(size: 10, weight: .bold, design: .rounded))
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Color(red: 0.08, green: 0.12, blue: 0.18).opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 10, y: 5)
    }

    private func grid(in rect: CGRect) -> Path {
        var path = Path()
        for index in 0...4 {
            let y = rect.minY + rect.height * CGFloat(index) / 4
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        for index in 1..<4 {
            let x = rect.minX + rect.width * CGFloat(index) / 4
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        return path
    }

    private func linePath(in rect: CGRect, series: [SeriesPoint]) -> Path {
        var path = Path()
        guard let first = series.first else {
            return path
        }

        let firstPoint = CGPoint(
            x: xPosition(for: first.index, count: max(samples.count, 2), in: rect),
            y: yPosition(for: first.value, in: rect)
        )
        path.move(to: firstPoint)

        guard series.count > 1 else {
            path.addLine(to: CGPoint(x: firstPoint.x + 0.1, y: firstPoint.y))
            return path
        }

        for point in series.dropFirst() {
            path.addLine(to: CGPoint(
                x: xPosition(for: point.index, count: max(samples.count, 2), in: rect),
                y: yPosition(for: point.value, in: rect)
            ))
        }
        return path
    }

    private func areaPath(in rect: CGRect, series: [SeriesPoint]) -> Path {
        var path = linePath(in: rect, series: series)
        guard let first = series.first, let last = series.last else {
            return Path()
        }
        let firstX = xPosition(for: first.index, count: max(samples.count, 2), in: rect)
        let lastX = xPosition(for: last.index, count: max(samples.count, 2), in: rect)
        path.addLine(to: CGPoint(x: lastX, y: rect.maxY))
        path.addLine(to: CGPoint(x: firstX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    private func plotRect(in size: CGSize) -> CGRect {
        CGRect(
            x: plotInsets.leading,
            y: plotInsets.top,
            width: max(1, size.width - plotInsets.leading - plotInsets.trailing),
            height: max(1, size.height - plotInsets.top - plotInsets.bottom)
        )
    }

    private func nearestSample(to point: CGPoint, in rect: CGRect) -> SamplePoint? {
        guard !samples.isEmpty else {
            return nil
        }
        if samples.count == 1 {
            return SamplePoint(index: 0, snapshot: samples[0])
        }
        let clampedX = min(max(point.x, rect.minX), rect.maxX)
        let progress = (clampedX - rect.minX) / rect.width
        let index = Int((progress * CGFloat(samples.count - 1)).rounded())
        return SamplePoint(index: index, snapshot: samples[index])
    }

    private func xPosition(for index: Int, count: Int, in rect: CGRect) -> CGFloat {
        guard count > 1 else {
            return rect.midX
        }
        return rect.minX + rect.width * CGFloat(index) / CGFloat(count - 1)
    }

    private func yPosition(for value: Double, in rect: CGRect) -> CGFloat {
        rect.minY + rect.height * CGFloat(1 - min(max(value, 0), 100) / 100)
    }

    private func percentLabel(_ value: Double?) -> String {
        guard let value else {
            return "--"
        }
        return "\(Int(value.rounded()))%"
    }

    private func timeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = chartDuration > 24 * 60 * 60 ? "M/d" : "HH:mm"
        return formatter.string(from: date)
    }

    private func fullTimeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = chartDuration > 24 * 60 * 60 ? "M/d HH:mm:ss" : "HH:mm:ss"
        return formatter.string(from: date)
    }

    private var chartDuration: TimeInterval {
        guard let first = samples.first?.updatedAt,
              let last = samples.last?.updatedAt
        else {
            return 0
        }
        return last.timeIntervalSince(first)
    }

    private struct SamplePoint {
        let index: Int
        let snapshot: QuotaSnapshot
    }

    private struct SeriesPoint {
        let index: Int
        let value: Double
    }
}
