import SwiftUI

struct DogsSection: View {
    let dogs: [Dog]

    var body: some View {
        if !dogs.isEmpty {
            Section {
                ForEach(dogs) { dog in
                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        Text(dog.name)
                            .fontWeight(.medium)
                        Text(dog.breed)
                            .font(.caption)
                            .foregroundStyle(Theme.warmBrown)
                    }
                    .listRowBackground(Theme.offWhite.opacity(Opacity.xSmall))
                }
            } header: {
                SectionHeader(
                    title: dogs.count == 1 ? "profile.dog" : "profile.dogs"
                )
            }
        }
    }
}
