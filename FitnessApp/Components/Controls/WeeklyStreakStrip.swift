import SwiftUI

struct WeeklyStreakStrip: View {
    let completedDays: Set<Int>
    let selectedDay: Int

    private let symbols = Calendar.current.shortWeekdaySymbols.map { String($0.prefix(3)).uppercased() }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                VStack(spacing: 10) {
                    Text(symbols[index])
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                    Text("\(20 + index)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(index == 6 ? AppTheme.orange : .white)
                    Image(systemName: completedDays.contains(index) ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(completedDays.contains(index) ? AppTheme.green : AppTheme.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(index == selectedDay ? AppTheme.card : .clear, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(6)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly training streak")
    }
}
