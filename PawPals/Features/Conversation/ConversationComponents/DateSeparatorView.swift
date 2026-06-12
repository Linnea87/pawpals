import SwiftUI

struct DateSeparatorView: View {
    let date: Date

    private var label: LocalizedStringKey {
        if Calendar.current.isDateInToday(date) { return "date.today" }
        if Calendar.current.isDateInYesterday(date) { return "date.yesterday" }
        return LocalizedStringKey(
            date.formatted(date: .abbreviated, time: .omitted)
        )
    }

    var body: some View {
        Text(label)
            .font(.caption)
            .foregroundStyle(Theme.warmBrown)
            .padding(.vertical, Spacing.small)
    }
}
