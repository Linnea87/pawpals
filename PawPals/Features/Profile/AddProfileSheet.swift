import SwiftUI

struct AddProfileSheet: View {

    let user: User?

    @Environment(ProfileViewModel.self) private var profileViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var name = ""
    @State private var bio = ""
    @State private var city = ""
    @State private var dogName = ""
    @State private var dogBreed = ""
    @State private var dogSize: DogSize? = nil
    @State private var selectedWalkTypes: Set<WalkType> = []
    @State private var showDeleteConfirm = false

    init(user: User? = nil) {
        self.user = user
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !dogName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !dogBreed.trimmingCharacters(in: .whitespaces).isEmpty &&
        dogSize != nil
    }

    var body: some View {
        ZStack {
            Theme.appBackground
                .ignoresSafeArea()

            List {
                Section {
                    TextField("profile.name", text: $name)
                        .listRowBackground(Theme.offWhite.opacity(0.6))
                    TextField("profile.bio", text: $bio, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .listRowBackground(Theme.offWhite.opacity(0.6))
                    TextField("profile.city", text: $city)
                        .listRowBackground(Theme.offWhite.opacity(0.6))
                } header: {
                    Text("profile.aboutUs")
                        .font(.subheadline)
                        .foregroundStyle(Theme.darkBrown)
                }
                .padding(.top, Spacing.large)

                Section {
                    TextField("dog.name", text: $dogName)
                        .listRowBackground(Theme.offWhite.opacity(0.6))
                    TextField("dog.breed", text: $dogBreed)
                        .listRowBackground(Theme.offWhite.opacity(0.6))
                    Picker("dog.size", selection: $dogSize) {
                        Text("dog.size.placeholder").tag(Optional<DogSize>.none)
                        ForEach(DogSize.allCases, id: \.self) { size in
                            Text(size.rawValue.capitalized).tag(Optional(size))
                        }
                    }
                    .listRowBackground(Theme.offWhite.opacity(0.6))
                } header: {
                    Text("dog.section")
                        .font(.subheadline)
                        .foregroundStyle(Theme.darkBrown)
                }

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
                        .listRowBackground(Theme.offWhite.opacity(0.6))
                    }
                } header: {
                    Text("profile.walk_preferences")
                        .font(.subheadline)
                        .foregroundStyle(Theme.darkBrown)
                }

                Button {
                    guard isFormValid, let size = dogSize else { return }
                    Task {
                        await profileViewModel.saveProfile(
                            name: name,
                            bio: bio,
                            city: city,
                            dogName: dogName,
                            dogBreed: dogBreed,
                            dogSize: size,
                            walkTypes: Array(selectedWalkTypes)
                        )
                        dismiss()
                    }
                } label: {
                    Text("dog.save")
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.small)
                        .background(isFormValid ? Theme.terracotta : Theme.lightPeach)
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
            city = user.city
            dogName = user.dogs.first?.name ?? ""
            dogBreed = user.dogs.first?.breed ?? ""
            dogSize = user.dogs.first?.size
            selectedWalkTypes = Set(user.preferences.walkTypes)
        }
    }
}

#Preview("Add") {
    NavigationStack { AddProfileSheet() }
        .environment(ProfileViewModel(userRepository: MockUserRepository(), user: .mock))
        .environment(AuthViewModel(repository: MockAuthRepository()))
}

#Preview("Edit") {
    NavigationStack { AddProfileSheet(user: .mock) }
        .environment(ProfileViewModel(userRepository: MockUserRepository(), user: .mock))
        .environment(AuthViewModel(repository: MockAuthRepository()))
}

private struct MockAuthRepository: AuthRepository {
    func signUp(email: String, password: String) async throws -> User { .mock }
    func signUpWithGoogle() async throws -> User { .mock }
    func signIn(email: String, password: String) async throws -> User { .mock }
    func signInWithGoogle() async throws -> User { .mock }
    func signOut() throws {}
    func deleteAccount() async throws {}
}

