import SwiftUI
import PhotosUI

struct ProfileView: View {

    let user: User
    let isOwner: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showSidebar = false
    @State private var showEditProfile = false
    @State private var showConversation = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .trailing) {
                Theme.appBackground
                    .ignoresSafeArea()

                List {
                    HStack(spacing: Spacing.medium) {
                        if isOwner {
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                avatarCircle
                            }
                        } else {
                            avatarCircle
                        }

                        VStack(alignment: .leading, spacing: Spacing.xSmall) {
                            Text(user.dogs.first != nil ? "\(user.name) / \(user.dogs.first!.name)" : user.name)
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

                    if !isOwner {
                        Button {
                            showConversation = true
                        } label: {
                            Text("profile.start_chat")
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.offWhite)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.terracotta)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
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
                    if isOwner {
                        Button {
                            withAnimation { showSidebar.toggle() }
                        } label: {
                            Label("menu", systemImage: showSidebar ? "xmark" : "line.3.horizontal")
                                .labelStyle(.iconOnly)
                        }
                    } else {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Theme.warmBrown)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showEditProfile) {
                AddProfileSheet()
            }
            .navigationDestination(isPresented: $showConversation) {
                // PP-020: Replace with ConversationView(conversation:, currentUserID:) when wired up
                Text("Conversation with \(user.name)")
            }
        }
    }

    private var avatarCircle: some View {
        Circle()
            .fill(Theme.lightPeach)
            .frame(width: IconSize.avatar, height: IconSize.avatar)
            .overlay {
                Image(systemName: "person")
                    .font(.system(size: IconSize.avatarIcon))
                    .foregroundStyle(Theme.offWhite)
            }
    }
}

#Preview("Owner") {
    ProfileView(user: .mock, isOwner: true)
}

#Preview("Visitor") {
    NavigationStack {
        ProfileView(user: .mock, isOwner: false)
    }
}
