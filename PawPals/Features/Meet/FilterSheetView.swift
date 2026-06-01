import SwiftUI

struct FilterSheetView: View {
    @Environment(MeetViewModel.self) private var viewModel
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: Spacing.large) {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Search radius")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.darkBrown)

                        Text("\(Int(viewModel.searchRadius)) km")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.terracotta)

                        Slider(
                            value: Binding(
                                get: { viewModel.searchRadius },
                                set: { viewModel.setRadius($0, userId: authVM.currentUserId) }
                            ),
                            in: 1...50,
                            step: 1
                        )
                        .tint(Theme.terracotta)

                        HStack {
                            Text("1 km")
                                .font(.caption)
                                .foregroundStyle(Theme.sageGreen)
                            Spacer()
                            Text("50 km")
                                .font(.caption)
                                .foregroundStyle(Theme.sageGreen)
                        }
                    }
                    .padding(Spacing.medium)
                    .background(Theme.offWhite.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Spacer()
                }
                .padding(Spacing.medium)
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.terracotta)
                }
            }
        }
    }
}

#Preview {
    FilterSheetView()
        .environment(MeetViewModel(locationService: LocationService()))
        .environment(AuthViewModel(repository: AuthService(), userRepository: UserService()))
}
