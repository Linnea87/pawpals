import SwiftUI

struct AddProfileSheet: View {

    @State private var dogName = ""
    @State private var dogBreed = ""
    @State private var dogSize: DogSize? = nil

    private var isFormValid: Bool {
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
                    TextField("dog.name", text: $dogName)
                        .listRowBackground(Color.white.opacity(0.6))

                    TextField("dog.breed", text: $dogBreed)
                        .listRowBackground(Color.white.opacity(0.6))

                    Picker("dog.size", selection: $dogSize) {
                        Text("dog.size.placeholder").tag(Optional<DogSize>.none)
                        ForEach(DogSize.allCases, id: \.self) { size in
                            Text(size.rawValue.capitalized).tag(Optional(size))
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.6))
                } header: {
                    Text("dog.section")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(.top, Spacing.large)

                Button {
                    guard isFormValid else { return }
                    // ViewModel call comes here
                } label: {
                    Text("dog.save")
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.small)
                        .background(isFormValid ? Theme.brand : Theme.muted)
                        .foregroundStyle(Theme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("profile.editProfile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AddProfileSheet()
    }
}
