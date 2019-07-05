//
//  AppDelegate.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 10/16/18.
//  Copyright © 2018 Guardian Angel. All rights reserved.
//

import UIKit
import UserNotifications


// User Default keys
let farenheit_celsius_key = "farenheit_celsius_key"
let meters_feet_key = "meters_feet_key"
let is_temp_enabled_key = "is_temp_enabled_key"
let max_temp_key = "max_temp_key"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    //static let serverKey = "AAAALZyy9Lo:APA91bFQbTtU4Q2JvXf60VSPvt-PErt-R70wloezBqjKX4p97IRIj-ED2a6_LOb_5dNRlADOwoFOGE9XveX-50-50cJT0xe_m_aXF2COqQw0baCqWqT1_wUKtuS8LJE4DvIQ4Qq4fj02"
    
    //static let notificationURL = "https://fcm.googleapis.com/fcm/send"
    
    static let isDebugging = false
    
    // Init temperature user settings
    static var farenheit_celsius = true
    static var meters_feet = true
    static var is_temp_enabled = true
    static var max_temp = 85

    let defaults = UserDefaults.standard
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Remote notification Setup
        registerForPushNotifications()

        //Navigation and root VC setup
        let viewController = DeviceViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
        
        // Set temperature user settings
        AppDelegate.farenheit_celsius = defaults.bool(forKey: farenheit_celsius_key)
        AppDelegate.meters_feet = defaults.bool(forKey: meters_feet_key)
        AppDelegate.is_temp_enabled = defaults.bool(forKey: is_temp_enabled_key)
        AppDelegate.max_temp = defaults.integer(forKey: max_temp_key)

        return true
    }
    
    func registerForPushNotifications() {
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
                (granted, error) in
                print("Permission granted: \(granted)")
                
                guard granted else { return }
                self.getNotificationSettings()
            }
        }
    }
    
    func getNotificationSettings() {
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                print("Notification settings: \(settings)")
                guard settings.authorizationStatus == .authorized else { return }
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        print("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Save temperature user settings
        defaults.set(AppDelegate.farenheit_celsius, forKey: farenheit_celsius_key)
        defaults.set(AppDelegate.meters_feet, forKey: meters_feet_key)
        defaults.set(AppDelegate.is_temp_enabled, forKey: is_temp_enabled_key)
        defaults.set(AppDelegate.max_temp, forKey: max_temp_key)
    }
    
    
}


