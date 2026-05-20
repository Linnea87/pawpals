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
                                .fill(Theme.lightPeach)
                                .frame(width: IconSize.avatar, height: IconSize.avatar)
                                .overlay {
                                    Image(systemName: "person")
                                        .font(.system(size: IconSize.avatarIcon))
                                        .foregroundStyle(Theme.offWhite)
                                }
                        }

                        VStack(alignment: .leading, spacing: Spacing.xSmall) {
                            Text(user.dog != nil ? "\(user.name) / \(user.dog!.name)" : user.name)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.darkBrown)

                            HStack(spacing: Spacing.xSmall) {
                                Image(systemName: "pawprint")
                                    .font(.caption2)
                                Text(user.city)
                                    .font(.subheadline)
                            }
                            .foregroundStyle(Theme.warmBrown)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, Spacing.small)

                    Section {
                        Text(user.bio)
                            .font(.callout)
                            .foregroundStyle(Theme.darkBrown)
                            .listRowBackground(Theme.offWhite.opacity(0.6))
                    } header: {
                        Text("profile.aboutUs")
                            .font(.subheadline)
                            .foregroundStyle(Theme.darkBrown)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

                if showSidebar {
                    VStack(alignment: .leading, spacing: Spacing.large) {
                        Text("profile.editProfile")
                            .foregroundStyle(Theme.darkBrown)
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
                    .background(Theme.offWhite)
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
