import SwiftUI

struct AddProfileSheet: View {

    let user: User?

    @Environment(ProfileViewModel.self) private var profileViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var name = ""
    @State private var bio = ""
    @State private var selectedWalkTypes: Set<WalkType> = []

    init(user: User? = nil) {
        self.user = user
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            Theme.appBackground
                .ignoresSafeArea()

            List {
                AboutInfoForm(name: $name, bio: $bio)

                DogsEditSection(
                    dogs: profileViewModel.user.dogs,
                    onRemove: { dog in
                        Task {
                            await profileViewModel.removeDog(dog.id)
                        }
                    },
                    onSave: { dog in
                        Task {
                            await profileViewModel.saveDog(dog)
                        }
                    }
                )

                WalkPrefsSection(selectedWalkTypes: $selectedWalkTypes)

                Button {
                    guard isFormValid else { return }
                    Task {
                        await profileViewModel.saveProfileInfo(
                            name: name,
                            bio: bio,
                            walkTypes: Array(selectedWalkTypes)
                        )
                        dismiss()
                    }
                } label: {
                    Text("dog.save")
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.small)
                        .background(
                            isFormValid ? Theme.terracotta : Theme.lightPeach
                        )
                        .foregroundStyle(Theme.offWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .padding(.vertical, Spacing.medium)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .onAppear {
            guard let user else { return }
            name = user.name
            bio = user.bio
            selectedWalkTypes = Set(user.preferences.walkTypes)
        }
    }
}

#Preview("Add") {
    NavigationStack { AddProfileSheet() }
        .profilePreviewEnvironments()
}

#Preview("Edit") {
    NavigationStack { AddProfileSheet(user: .mock) }
        .profilePreviewEnvironments()
}
