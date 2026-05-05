import Charts
import SwiftUI

struct StrengthLineChart: View {
    let data: [DailyVolume]

    var body: some View {
        Chart(data) { point in
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Training Volume", point.volume)
            )
            .foregroundStyle(AppTheme.green.opacity(0.22))

            LineMark(
                x: .value("Date", point.date),
                y: .value("Training Volume", point.volume)
            )
            .interpolationMethod(.monotone)
            .foregroundStyle(AppTheme.green)

            PointMark(
                x: .value("Date", point.date),
                y: .value("Training Volume", point.volume)
            )
            .foregroundStyle(AppTheme.green)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4))
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 220)
        .accessibilityLabel("Training volume over time")
    }
}
