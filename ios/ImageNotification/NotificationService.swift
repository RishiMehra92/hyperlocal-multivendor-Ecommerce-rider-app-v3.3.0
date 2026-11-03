import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // 1. Look for the image URL in the notification payload
            // This checks both 'fcm_options' and 'image' keys common in FCM
            var urlString: String? = nil
            if let fcmOptions = bestAttemptContent.userInfo["fcm_options"] as? [String: Any],
               let image = fcmOptions["image"] as? String {
                urlString = image
            } else if let image = bestAttemptContent.userInfo["image"] as? String {
                urlString = image
            }
            
            // 2. If we found a URL, download and attach it
            if let urlString = urlString, let fileUrl = URL(string: urlString) {
                downloadAndSave(url: fileUrl) { (localUrl) in
                    if let localUrl = localUrl {
                        do {
                            let attachment = try UNNotificationAttachment(identifier: "image", url: localUrl, options: nil)
                            bestAttemptContent.attachments = [attachment]
                        } catch {
                            print("Error creating attachment: \(error)")
                        }
                    }
                    contentHandler(bestAttemptContent)
                }
            } else {
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    // Helper to download the image
    private func downloadAndSave(url: URL, completion: @escaping (URL?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { (location, response, error) in
            guard let location = location, error == nil else {
                completion(nil)
                return
            }
            
            let tmpDirectory = FileManager.default.temporaryDirectory
            let destination = tmpDirectory.appendingPathComponent(url.lastPathComponent)
            
            try? FileManager.default.removeItem(at: destination)
            
            do {
                try FileManager.default.moveItem(at: location, to: destination)
                completion(destination)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
