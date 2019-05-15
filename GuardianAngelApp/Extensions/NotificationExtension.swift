//
//  NotificationExtension.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 10/20/18.
//  Copyright © 2018 Guardian Angel. All rights reserved.
//

import Foundation
import UserNotifications
import Alamofire
import Firebase

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
    
    /// Local notification sent when you have gone too far away from the child
    func sendLocalNotificationLeftRegion() {
        let center = UNUserNotificationCenter.current()
        print("sending left region notification")
        let content = UNMutableNotificationContent()
        content.title = "You are too far from your baby"
        content.body = "Save your baby!"
        content.sound = UNNotificationSound.default
        content.threadIdentifier = "guardian-angel"
        let identifier = "LocalLeftRegion"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content, trigger: trigger)
        center.add(request) { (error : Error?) in
            if let theError = error {
                print(theError.localizedDescription)
            }
        }
    }
    
    /// Notification for temperation
    func sendLocalNotificationTemperature() {
        let center = UNUserNotificationCenter.current()
        print("sending temp notification")
        let content = UNMutableNotificationContent()
        content.title = "It's too hot!"
        content.body = "Save your baby now!"
        content.sound = UNNotificationSound.default
        content.threadIdentifier = "guardian-angel"
        let identifier = "LocalTemperature"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content, trigger: trigger)
        center.add(request) { (error : Error?) in
            if let theError = error {
                print(theError.localizedDescription)
            }
        }
    }
    
    // **************** Debugging purposes notifications *************************//
    func sendLocalNotificationEnteredRegion() {
        let center = UNUserNotificationCenter.current()
        print("sending entered region notification")
        let content = UNMutableNotificationContent()
        content.title = "Entered Region"
        content.body = "Save your baby now!"
        content.sound = UNNotificationSound.default
        content.threadIdentifier = "guardian-angel"
        let identifier = "LocalEnteredRegion"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content, trigger: trigger)
        center.add(request) { (error : Error?) in
            if let theError = error {
                print(theError.localizedDescription)
            }
        }
    }

    @objc func sendLocalNotificationConnected() {
        let center = UNUserNotificationCenter.current()
        print("sending connected notification")
        let content = UNMutableNotificationContent()
        content.title = "UART Connected!"
        content.body = "Save your baby now!"
        content.sound = UNNotificationSound.default
        content.threadIdentifier = "guardian-angel"
        let identifier = "LocalConnected"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content, trigger: trigger)
        center.add(request) { (error : Error?) in
            if let theError = error {
                print(theError.localizedDescription)
            }
        }
    }
    
    @objc func sendLocalNotificationDisconnected() {
        let center = UNUserNotificationCenter.current()
        print("sending disconnected notification")
        let content = UNMutableNotificationContent()
        content.title = "UART Disconnected!"
        content.body = "Save your baby now!"
        content.sound = UNNotificationSound.default
        content.threadIdentifier = "guardian-angel"
        let identifier = "LocalDisconnected"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content, trigger: trigger)
        center.add(request) { (error : Error?) in
            if let theError = error {
                print(theError.localizedDescription)
            }
        }
    }
    
    @objc func sendLocalNotificationBackgroundScanning() {
        let center = UNUserNotificationCenter.current()
        print("sending background scanning notification")
        let content = UNMutableNotificationContent()
        content.title = "Started Background Scanning!"
        content.body = "Save your baby now!"
        content.sound = UNNotificationSound.default
        content.threadIdentifier = "guardian-angel"
        let identifier = "LocalDisconnected"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content, trigger: trigger)
        center.add(request) { (error : Error?) in
            if let theError = error {
                print(theError.localizedDescription)
            }
        }
    }
    
    // *********************************************************************//
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler( [.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func fetchMessages(_ name: String) {
        Database.database().reference().child("users").observeSingleEvent(of: .value) { (snapshot) in
                guard let dictionary = snapshot.value as? [String:Any] else {return}
                dictionary.forEach({(key,value) in
                    //print("key: \(key)")
                    //print("value: \(value)\n")
                    guard let dict = value as? [String: String]  else { return }
                    if let name = dict["name"], name == "Hudson" {
                        //self.sendPushNotification(To: name)
                    }
                })
            }
        }

    func sendPushNotification(){
        let title = "Push Notification"
        let body = "Save your baby"
        let user = "Hudson"
        print("user: \(user)")
        var headers: HTTPHeaders = HTTPHeaders()
        headers = ["Content-Type":"application/json","Authorization":"key=\(AppDelegate.serverKey)"]
        let notification = ["to":"\(user)","notification":["body":body,"title":title,"badge":1,"sound":"default"]] as [String:Any]
        Alamofire.request(AppDelegate.notificationURL as String, method: .post, parameters: notification, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            print("Response: \(response)")
        }

    }
}
