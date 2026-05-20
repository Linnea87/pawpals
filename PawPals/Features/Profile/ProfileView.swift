import SwiftUI
import PhotosUI

struct ProfileView: View {

    let user: User
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showSidebar = false
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .trailing) {
                Theme.appBackground
                    .ignoresSafeArea()

                List {
                    HStack(spacing: Spacing.medium) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Circle()
                                .fill(Theme.muted)
                                .frame(width: IconSize.avatar, height: IconSize.avatar)
                                .overlay {
                                    Image(systemName: "person")
                                        .font(.system(size: IconSize.avatarIcon))
                                        .foregroundStyle(.white)
                                }
                        }

                        VStack(alignment: .leading, spacing: Spacing.xSmall) {
                            Text(user.dog != nil ? "\(user.name) / \(user.dog!.name)" : user.name)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.textPrimary)

                            HStack(spacing: Spacing.xSmall) {
                                Image(systemName: "pawprint")
                                    .font(.caption2)
                                Text(user.city)
                                    .font(.subheadline)
                            }
                            .foregroundStyle(Theme.textPrimary.opacity(0.5))
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, Spacing.small)

                    Section {
                        Text(user.bio)
                            .font(.callout)
                            .foregroundStyle(Theme.textPrimary)
                            .listRowBackground(Color.white.opacity(0.6))
                    } header: {
                        Text("profile.aboutUs")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

                if showSidebar {
                    VStack(alignment: .leading, spacing: Spacing.large) {
                        Text("profile.editProfile")
                            .foregroundStyle(Theme.textPrimary)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showSidebar = false
                                showEditProfile = true
                            }

                        Divider()

                        Spacer()
                    }
                    .padding(.top, Spacing.sidebarTop)
                    .padding(.horizontal, Spacing.large)
                    .containerRelativeFrame(.horizontal, count: 3, span: 2, spacing: Spacing.none)
                    .frame(maxHeight: .infinity)
                    .background(Theme.background)
                    .ignoresSafeArea()
                    .transition(.move(edge: .trailing))
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation { showSidebar.toggle() }
                    } label: {
                        Label("menu", systemImage: showSidebar ? "xmark" : "line.3.horizontal")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .navigationDestination(isPresented: $showEditProfile) {
                AddProfileSheet()
            }
        }
    }
}

#Preview {
    ProfileView(user: .mock)
}
