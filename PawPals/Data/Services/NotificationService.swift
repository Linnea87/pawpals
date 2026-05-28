import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications

/// Handles everything related to push notifications:
/// - Requesting permission from the user
/// - Receiving and storing the device push notification token
/// - Reacting to notification taps and exposing the conversation to navigate to
///
/// Conforms to UNUserNotificationCenterDelegate (Apple) and MessagingDelegate (Firebase).
/// NSObject is required because Apple's delegate protocols need an Objective-C compatible base.
@Observable
final class NotificationService: NSObject {

    var pendingConversationID: String?
    var pushNotificationToken: String?

    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }
    /// Asks the user for permission to show notifications.
    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            guard granted else { return }
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            print(
                "Push notification permission request failed: \(error.localizedDescription)"
            )
        }
    }
    /// Saves the push notification token to Firestore via the repository.
    func savePushNotificationToken(_ token: String, for userID: String) async {
        do {
            try await userRepository.savePushNotificationToken(
                token,
                userID: userID
            )
        } catch {
            print(
                "Failed to save push notification token: \(error.localizedDescription)"
            )
        }
    }

}

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Called when a notification arrives while the app is open in the foreground.
    /// We tell it to show the banner, play the sound, and update the badge anyway.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    /// Called when the user taps a notification.
    /// Extracts the conversationID from the notification payload and stores it.
    /// AppNavigationView picks this up and navigates to the correct conversation.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let conversationID = userInfo["conversationID"] as? String {
            pendingConversationID = conversationID
        }
        completionHandler()
    }

}
extension NotificationService: MessagingDelegate {

    /// Called by Firebase when the device receives a new push notification token.
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        pushNotificationToken = fcmToken
    }
}
