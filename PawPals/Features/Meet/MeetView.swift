import SwiftUI

struct MeetView: View {
    @Environment(MeetViewModel.self) private var viewModel
    
    var body: some View {
        @Bindable var vm = viewModel
        NavigationStack {
            Text("Meet")
                .sheet(item: $vm.selectedUser) { user in
                    NavigationStack {
                        UserProfileView(user: user)
                    }
                }
        }
    }
}

#Preview {
    MeetView()
        .environment(MeetViewModel())
}

