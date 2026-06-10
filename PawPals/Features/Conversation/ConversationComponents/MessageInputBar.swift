import SwiftUI
import PhotosUI

struct MessageInputBar: View {
    @Binding var text: String
    let onSend: () -> Void
    let onImagePick: (UIImage) -> Void

    // TODO [PP-028]: Reset selectedPhoto after upload
    // so user can pick the same image twice
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        HStack(spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {

                TextField("chat.messagePlaceholder", text: $text)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(Theme.offWhite)
            .clipShape(Capsule())

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Image(systemName: "photo")
                    .font(.system(size: Spacing.large, weight: .semibold))
                    .foregroundStyle(Theme.warmBrown)
                    .padding(Spacing.medium)
                    .background(Theme.lightPeach)
                    .clipShape(Circle())
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(
                        type: Data.self
                    ),
                        let image = UIImage(data: data)
                    {
                        onImagePick(image)
                        selectedPhoto = nil
                    }
                }
            }

            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: Spacing.large, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(Spacing.medium)
                    .background(
                        text.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Theme.sageGreen
                            : Theme.terracotta
                    )
                    .clipShape(Circle())
            }
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.medium)

    }
}
