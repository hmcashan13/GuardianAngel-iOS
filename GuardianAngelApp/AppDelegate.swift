//
//  AppDelegate.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 10/16/18.
//  Copyright © 2018 Guardian Angel. All rights reserved.
//

import UIKit
import UserNotifications
import Firebase
import GoogleSignIn
import FacebookCore

// User Default keys
let farenheit_celsius_key: String = "farenheit_celsius_key"
let meters_feet_key: String = "meters_feet_key"
let is_temp_enabled_key: String = "is_temp_enabled_key"
let max_temp_key: String = "max_temp_key"

// Used to turn on/off print statements and other debugging information
let isDebugging: Bool = true

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    //static let serverKey = "AAAALZyy9Lo:APA91bFQbTtU4Q2JvXf60VSPvt-PErt-R70wloezBqjKX4p97IRIj-ED2a6_LOb_5dNRlADOwoFOGE9XveX-50-50cJT0xe_m_aXF2COqQw0baCqWqT1_wUKtuS8LJE4DvIQ4Qq4fj02"
    
    //static let notificationURL = "https://fcm.googleapis.com/fcm/send"

    private let standardUserDefaults: [String:Any] = [farenheit_celsius_key : true, meters_feet_key :  true, is_temp_enabled_key : true, max_temp_key : 85]
    // Init temperature user settings
    static var farenheit_celsius: Bool = true
    static var meters_feet: Bool = true
    static var is_temp_enabled: Bool = true
    static var max_temp: Int = 85
    
    static var user: LocalUser?
    
    let defaults = UserDefaults.standard
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Remote notification Setup
        registerForPushNotifications()

        // Firebase/Google Setup
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        
        // Facebook Setup
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        //Navigation and root VC setup
        let deviceViewController = DeviceViewController()
        let gpsViewController = GPSViewController()
        deviceViewController.tabBarItem = UITabBarItem(title: "Device", image: UIImage(named: "device"), tag: 0)
        gpsViewController.tabBarItem = UITabBarItem(title: "GPS", image: UIImage(named: "gps"), tag: 1)
        let controllers = [deviceViewController, gpsViewController]
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = controllers.map { UINavigationController(rootViewController: $0)}
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = tabBarController
        //self.window?.rootViewController = navigationController
        //self.window?.makeKeyAndVisible()
        
        // Set temperature user settings
        UserDefaults.standard.register(defaults:standardUserDefaults)
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
                if isDebugging {
                    print("Permission granted: \(granted)")
                }
                
                guard granted else { return }
                self.getNotificationSettings()
            }
        }
    }
    
    func getNotificationSettings() {
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                if isDebugging {
                    print("Notification settings: \(settings)")
                }
                guard settings.authorizationStatus == .authorized else { return }
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        if isDebugging {
            print("Device Token: \(token)")
        }
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
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        ApplicationDelegate.shared.application(app, open: url, options: options)
        return true
    }
}
