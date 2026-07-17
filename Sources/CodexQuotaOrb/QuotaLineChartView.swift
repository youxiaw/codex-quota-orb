import SwiftUI

struct QuotaLineChartView: View {
    let samples: [QuotaSnapshot]
    @State private var hoverLocation: CGPoint?

    private let plotInsets = EdgeInsets(top: 18, leading: 36, bottom: 28, trailing: 14)

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.2),
                                Color.white.opacity(0.045)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                grid(in: plotRect(in: proxy.size))
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)

                axisLabels(in: proxy.size)

                linePath(in: plotRect(in: proxy.size), values: weeklyValues)
                    .stroke(Color.cyan.opacity(0.92), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                linePath(in: plotRect(in: proxy.size), values: fiveHourValues)
                    .stroke(Color.orange.opacity(0.88), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                legend

                if let hover = hoverLocation,
                   let point = nearestSample(to: hover, in: plotRect(in: proxy.size)) {
                    hoverOverlay(point, in: plotRect(in: proxy.size))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

    private var weeklyValues: [Double] {
        samples.compactMap { $0.weekly?.remainingPercent }
    }

    private var fiveHourValues: [Double] {
        samples.compactMap { $0.fiveHour?.remainingPercent }
    }

    private var legend: some View {
        VStack {
            HStack(spacing: 10) {
                legendItem(color: .cyan, text: "Week")
                legendItem(color: .orange, text: "5h")
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
                .foregroundStyle(.secondary)
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
            .foregroundStyle(.secondary.opacity(0.85))
            .frame(width: 26, alignment: .trailing)
            .position(x: 18, y: y + 7)
    }

    private func xLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9.5, weight: .bold, design: .rounded))
            .foregroundStyle(.secondary.opacity(0.85))
    }

    private func hoverOverlay(_ samplePoint: SamplePoint, in rect: CGRect) -> some View {
        let x = xPosition(for: samplePoint.index, count: max(samples.count, 2), in: rect)
        return ZStack(alignment: .topLeading) {
            Path { path in
                path.move(to: CGPoint(x: x, y: rect.minY))
                path.addLine(to: CGPoint(x: x, y: rect.maxY))
            }
            .stroke(Color.white.opacity(0.28), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

            if let weekly = samplePoint.snapshot.weekly?.remainingPercent {
                dot(at: CGPoint(x: x, y: yPosition(for: weekly, in: rect)), color: .cyan)
            }
            if let fiveHour = samplePoint.snapshot.fiveHour?.remainingPercent {
                dot(at: CGPoint(x: x, y: yPosition(for: fiveHour, in: rect)), color: .orange)
            }

            tooltip(samplePoint.snapshot)
                .position(
                    x: min(max(x + 54, rect.minX + 64), rect.maxX - 64),
                    y: rect.minY + 34
                )
        }
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
                .foregroundStyle(.cyan)
            Text("5h \(percentLabel(snapshot.fiveHour?.remainingPercent))")
                .foregroundStyle(.orange)
        }
        .font(.system(size: 10, weight: .bold, design: .rounded))
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.22), radius: 10, y: 5)
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

    private func linePath(in rect: CGRect, values: [Double]) -> Path {
        var path = Path()
        guard values.count > 1 else {
            return path
        }

        for (index, value) in values.enumerated() {
            let x = xPosition(for: index, count: values.count, in: rect)
            let y = yPosition(for: value, in: rect)
            let point = CGPoint(x: x, y: y)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
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
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func fullTimeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    private struct SamplePoint {
        let index: Int
        let snapshot: QuotaSnapshot
    }
}
