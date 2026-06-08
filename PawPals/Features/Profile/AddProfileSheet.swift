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

    @State private var showAddDogForm = false
    

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
                    ForEach(profileViewModel.user.dogs) { dog in
                        VStack(alignment: .leading, spacing: Spacing.xSmall) {
                            Text(dog.name)
                                .fontWeight(.medium)
                            Text(dog.breed)
                                .font(.caption)
                                .foregroundStyle(Theme.warmBrown)
                        }
                        .listRowBackground(Theme.offWhite.opacity(0.6))
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { await profileViewModel.removeDog(dog.id) }
                            } label: {
                                Label("Ta bort", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(profileViewModel.user.dogs.count == 1 ? "profile.dog" : "profile.dogs")
                        Spacer()
                        Button {
                            withAnimation { showAddDogForm.toggle() }
                        } label: {
                            Image(systemName: showAddDogForm ? "minus" : "plus")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(Theme.darkBrown)
                }
                
                if showAddDogForm {
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
                        Button {
                            guard !dogName.isEmpty, !dogBreed.isEmpty, let size = dogSize else { return }
                            let newDog = Dog(
                                id: UUID().uuidString,
                                name: dogName.trimmingCharacters(in: .whitespaces),
                                breed: dogBreed.trimmingCharacters(in: .whitespaces),
                                age: 0,
                                size: size
                            )
                            Task {
                                await profileViewModel.saveDog(newDog)
                                dogName = ""
                                dogBreed = ""
                                dogSize = nil
                                withAnimation { showAddDogForm = false }
                            }
                        } label: {
                            Text("dog.save")
                                .foregroundStyle(Theme.terracotta)
                        }
                        .listRowBackground(Theme.offWhite.opacity(0.6))
                    } header: {
                        Text("dog.section")
                            .font(.subheadline)
                            .foregroundStyle(Theme.darkBrown)
                    }
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
                    guard isFormValid else { return }
                    Task {
                        await profileViewModel.saveProfileInfo(
                            name: name,
                            bio: bio,
                            city: city,
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
            selectedWalkTypes = Set(user.preferences.walkTypes)
        }
    }
    
    #Preview("Add") {
        NavigationStack { AddProfileSheet() }
            .environment(ProfileViewModel(userRepository: MockUserRepository(), user: .mock))
    }
    
    #Preview("Edit") {
        NavigationStack { AddProfileSheet(user: .mock) }
            .environment(ProfileViewModel(userRepository: MockUserRepository(), user: .mock))
    }
    
}


#Preview("Add") {
    NavigationStack { AddProfileSheet() }
        .environment(ProfileViewModel(userRepository: MockUserRepository(), user: .mock))
        .environment(AuthViewModel(repository: MockAuthRepository(), userRepository: MockUserRepository()))
}

#Preview("Edit") {
    NavigationStack { AddProfileSheet(user: .mock) }
        .environment(ProfileViewModel(userRepository: MockUserRepository(), user: .mock))
        .environment(AuthViewModel(repository: MockAuthRepository(), userRepository: MockUserRepository()))
}

