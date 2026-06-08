import SwiftUI

  struct AvatarView: View {
      let photoURL: String?
      let size: CGFloat
      let iconSize: CGFloat

      @State private var loadedImage: Image?

      var body: some View {
          Circle()
              .fill(Theme.lightPeach)
              .frame(width: size, height: size)
              .overlay {
                  if let loadedImage {
                      loadedImage
                          .resizable()
                          .scaledToFill()
                          .clipShape(Circle())
                  } else {
                      Image(systemName: "person")
                          .font(.system(size: iconSize))
                          .foregroundStyle(Theme.offWhite)
                  }
              }
              .task(id: photoURL) {
                  guard let photoURL, let url = URL(string: photoURL) else {
                      loadedImage = nil
                      return
                  }
                  guard let (data, _) = try? await URLSession.shared.data(from: url),
                        let uiImage = UIImage(data: data) else { return }
                  loadedImage = Image(uiImage: uiImage)
              }
      }
  }

  #Preview {
      AvatarView(photoURL: nil, size: IconSize.avatar, iconSize: IconSize.avatarIcon)
          .padding()
  }
