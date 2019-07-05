//
//  NotificationExtension.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 10/20/18.
//  Copyright © 2018 Guardian Angel. All rights reserved.
//

import Foundation
import UserNotifications

extension DeviceViewController: UNUserNotificationCenterDelegate {
    /// Set up the ability to send local notifications
    func setupNotification() {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound]
        center.requestAuthorization(options: options) {
            (granted, error) in
            if !granted {
                print("Something went wrong")
            }
        }
        center.getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                // Notifications not allowed
                print("Notifications not allowed")
            }
        }
    }
    
    /// Local notification sent when you have gone too far away from the cushion
    func sendTooFarNotification() {
        sendNotification(description: "You are too far from the cushion")
    }
    
    /// Local notification for temperature being too high
    func sendTemperatureNotification() {
        sendNotification(description:  "It's too hot!")
    }
    
    func sendNotification(description: String) {
        let center = UNUserNotificationCenter.current()
        print("sending background scanning notification")
        let content = UNMutableNotificationContent()
        content.title = "Started Background Scanning!"
        content.body = "Just a friendly reminder"
        content.sound = UNNotificationSound.default
        content.threadIdentifier = "guardian-angel"
        let identifier = "LocalScanning"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content, trigger: trigger)
        center.add(request) { (error : Error?) in
            if let theError = error {
                print(theError.localizedDescription)
            }
        }
    }
}
