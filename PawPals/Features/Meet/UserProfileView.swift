import SwiftUI

struct UserProfileView: View {
    let user: User
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                VStack(spacing: 8) {
                    Circle()
                        .fill(Theme.offWhite)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(Theme.terracotta)
                        )
                    
                    Text(user.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let dog = user.dogs.first {
                        Text(dog.name)
                            .font(.subheadline)
                            .foregroundStyle(Theme.lightPeach)
                    }
                    
                    Text(user.city)
                        .font(.caption)
                        .foregroundStyle(Theme.lightPeach)
                    
                    if let distance = user.distance {
                        Text(String(format: "%.1f km away", distance))
                            .font(.caption)
                            .foregroundStyle(Theme.lightPeach)
                    }
                }
                
                if !user.bio.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("profile.about_us")
                            .font(.headline)
                        Text(user.bio)
                            .font(.body)
                            .foregroundStyle(Theme.lightPeach)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                
                if let dog = user.dogs.first {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("profile.dog_info")
                            .font(.headline)
                        Text("\(dog.breed) · \(dog.age) years · \(dog.size.rawValue)")
                            .font(.body)
                            .foregroundStyle(Theme.lightPeach)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                
                if !user.preferences.walkTypes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("profile.walk_preferences")
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(user.preferences.walkTypes) { walkType in
                                    Text(walkType.rawValue)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Theme.terracotta)
                                        .foregroundStyle(Theme.offWhite)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                
                Button {
                } label: {
                    Text("profile.start_chat")
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.offWhite)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.terracotta)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .padding(.top, 32)
            .padding(.bottom, 24)
        }
        .background(Theme.appBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.warmBrown)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        UserProfileView(user: .mock)
    }
}

