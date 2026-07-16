import SwiftUI

struct QuotaLineChartView: View {
    let samples: [QuotaSnapshot]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.12))

                grid(in: proxy.size)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)

                linePath(in: proxy.size, values: weeklyValues)
                    .stroke(Color.cyan.opacity(0.92), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                linePath(in: proxy.size, values: fiveHourValues)
                    .stroke(Color.orange.opacity(0.88), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }
        }
    }

    private var weeklyValues: [Double] {
        samples.compactMap { $0.weekly?.remainingPercent }
    }

    private var fiveHourValues: [Double] {
        samples.compactMap { $0.fiveHour?.remainingPercent }
    }

    private func grid(in size: CGSize) -> Path {
        var path = Path()
        for index in 1..<4 {
            let y = size.height * CGFloat(index) / 4
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }
        return path
    }

    private func linePath(in size: CGSize, values: [Double]) -> Path {
        var path = Path()
        guard values.count > 1 else {
            return path
        }

        for (index, value) in values.enumerated() {
            let x = size.width * CGFloat(index) / CGFloat(values.count - 1)
            let y = size.height * CGFloat(1 - min(max(value, 0), 100) / 100)
            let point = CGPoint(x: x, y: y)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }
}
