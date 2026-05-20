import Foundation

@Observable
final class MeetViewModel {
    var selectedUser: User?
    
    func selectedUser(_user: User) {
        selectedUser = _user
    }
}

