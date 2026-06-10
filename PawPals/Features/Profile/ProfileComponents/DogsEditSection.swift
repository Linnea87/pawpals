import SwiftUI

struct DogsEditSection: View {
    let dogs: [Dog]
    let onRemove: (Dog) -> Void
    let onSave: (Dog) -> Void

    @State private var showAddForm = false
    @State private var name = ""
    @State private var breed = ""
    @State private var size: DogSize? = nil

    var body: some View {
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
                .swipeActions {
                    Button(role: .destructive) {
                        onRemove(dog)
                    } label: {
                        Label("Ta bort", systemImage: "trash")
                    }
                }
            }
        } header: {
            HStack {
                SectionHeader(
                    title: dogs.count == 1 ? "profile.dog" : "profile.dogs"
                )
                Spacer()
                Button {
                    withAnimation { showAddForm.toggle() }
                } label: {
                    Image(systemName: showAddForm ? "minus" : "plus")
                }
            }
            .font(.subheadline)
            .foregroundStyle(Theme.darkBrown)
        }

        if showAddForm {
            Section {
                TextField("dog.name", text: $name)
                    .listRowBackground(Theme.offWhite.opacity(Opacity.xSmall))
                TextField("dog.breed", text: $breed)
                    .listRowBackground(Theme.offWhite.opacity(Opacity.xSmall))
                Picker("dog.size", selection: $size) {
                    Text("dog.size.placeholder").tag(Optional<DogSize>.none)
                    ForEach(DogSize.allCases, id: \.self) { size in
                        Text(size.rawValue.capitalized).tag(Optional(size))
                    }
                }
                .listRowBackground(Theme.offWhite.opacity(Opacity.xSmall))
                Button {
                    guard !name.isEmpty, !breed.isEmpty, let size
                    else { return }
                    let newDog = Dog(
                        id: UUID().uuidString,
                        name: name.trimmingCharacters(in: .whitespaces),
                        breed: breed.trimmingCharacters(in: .whitespaces),
                        age: 0,
                        size: size
                    )
                    onSave(newDog)
                    name = ""
                    breed = ""
                    self.size = nil
                    withAnimation { showAddForm = false }
                } label: {
                    Text("dog.save")
                        .foregroundStyle(Theme.terracotta)
                }
                .listRowBackground(Theme.offWhite.opacity(Opacity.xSmall))
            } header: {
                SectionHeader(title: "dog.section")
            }
        }
    }
}
