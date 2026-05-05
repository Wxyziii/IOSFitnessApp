import Charts
import SwiftUI

struct MuscleBreakdownChart: View {
    let shares: [MuscleShare]

    var body: some View {
        Chart(shares) { share in
            SectorMark(
                angle: .value("Training Volume", share.value),
                innerRadius: .ratio(0.58),
                angularInset: 1
            )
            .foregroundStyle(by: .value("Muscle Group", share.group.rawValue))
        }
        .chartLegend(position: .trailing)
        .frame(height: 220)
        .accessibilityLabel("Muscle group training breakdown")
    }
}
