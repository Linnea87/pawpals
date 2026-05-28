import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications

@Observable
final class NotificationService: NSObject
{

    var pendingConversationID: String?
    var pushNotificationToken: String?

    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }

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

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

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
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        pushNotificationToken = fcmToken
    }
}
