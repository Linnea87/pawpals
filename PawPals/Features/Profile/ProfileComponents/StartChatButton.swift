import SwiftUI

struct StartChatButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("profile.start.chat")
                .fontWeight(.bold)
                .foregroundStyle(Theme.offWhite)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.terracotta)
                .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
