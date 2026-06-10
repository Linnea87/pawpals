import SwiftUI

struct WalkPrefsSection: View {
    @Binding var selectedWalkTypes: Set<WalkType>

    var body: some View {
        Section {
            ForEach(WalkType.allCases) { walkType in
                Button {
                    if selectedWalkTypes.contains(walkType) {
                        selectedWalkTypes.remove(walkType)
                    } else {
                        selectedWalkTypes.insert(walkType)
                    }
                } label: {
                    HStack {
                        Text(walkType.rawValue)
                            .foregroundStyle(Theme.darkBrown)
                        Spacer()
                        if selectedWalkTypes.contains(walkType) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Theme.terracotta)
                        }
                    }
                }
                .listRowBackground(Theme.offWhite.opacity(Opacity.xSmall))
            }
        } header: {
            SectionHeader(title: "profile.walkPreferences")
        }
    }
}
