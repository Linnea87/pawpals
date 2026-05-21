import Foundation

@Observable
final class MeetViewModel {
    var selectedUser: User?
    var allNearbyUsers: [User] = []
        var filteredUsers: [User] = []
        var selectedFilter: WalkType? = nil
        var isLoading = false
        var errorMessage: String? = nil


        func loadNearbyUsers() async {
            isLoading = true
            allNearbyUsers = [.mock] // Replace with real firebase later
            applyFilter()
            isLoading = false
        }

        func selectFilter(_ filter: WalkType?) {
            selectedFilter = filter
            applyFilter()
        }

        private func applyFilter() {
            guard let filter = selectedFilter else {
                filteredUsers = allNearbyUsers
                return
            }
            filteredUsers = allNearbyUsers.filter {
                $0.preferences.walkTypes.contains(filter)
            }
            
            func loadNearbyUsers() async {
                isLoading = true
                errorMessage = nil
                do {
                    // TODO: riktigt anrop
                    allNearbyUsers = [.mock]
                    applyFilter()
                } catch {
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        }
    }
