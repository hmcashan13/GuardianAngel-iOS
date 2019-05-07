//
//  DeviceViewController.swift
//  GuardianAngel
//
//  Created by Hudson Mcashan on 2/1/18.
//  Copyright © 2018 Hudson Mcashan. All rights reserved.
//

import Firebase
import Alamofire
import UIKit
import CoreBluetooth
import UserNotifications
import CoreLocation
import FBSDKLoginKit
import GoogleSignIn

class DeviceViewController: UIViewController {
    // Beacon Regions
    let beaconRegion = CLBeaconRegion(
        proximityUUID: UUID(uuidString:"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!,
        major: 0,
        minor: 0,
        identifier: "Guardian")
    
    let beaconRegion2 = CLBeaconRegion(
        proximityUUID: UUID(uuidString:"FDA50693-A4E2-4FB1-AFCF-C6EB07647825")!,
        major: 10011,
        minor: 10011,
        identifier: "Guardian")
    // Beacon variables
    var proximity = "Not Connected"
    var beacon_is_connected: Bool = false
    var locationManager: CLLocationManager?
    var beaconsToRange = [CLBeaconRegion]()
    var leftCount = 0
    var unknownCount = 0
    let peripheralName = "Guardian Angel"
    
    // UART variables
    let cbarray =  [CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")]
    let UART_UUID = UUID(uuidString: "F0B6C05F-15A0-9F38-BBD9-5E117CF7DC7A")
    var txCharacteristic : CBCharacteristic?
    var rxCharacteristic : CBCharacteristic?
    var blePeripheral : CBPeripheral?
    var characteristicASCIIValue = NSString()
    var uart_is_connected: Bool = false
    var centralManager: CBCentralManager?
    var RSSIs = [NSNumber]()
    var selectedPeripheral: CBPeripheral?
    var peripherals: [CBPeripheral] = []
    var characteristicValue = [CBUUID: NSData]()
    var characteristics = [String : CBCharacteristic]()
    var is_baby_in_seat: Bool = false
    var repeatScan = true
    var maxTemp: Int = 80
    
    var timer = Timer()
    let center = UNUserNotificationCenter.current()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup UI
        view.backgroundColor = UIColor.purple
        
        setupDeviceContainerView()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(goToSettings))
        
        // Setup Notifications
        center.delegate = self
        setupNotification()
 
        // Setup UART
        centralManager = CBCentralManager(delegate: self, queue: nil)
        updateIncomingData()
        
        // Setup Beacon
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false
        locationManager?.requestAlwaysAuthorization()
        
        // Setup Google Sign in delegate
        GIDSignIn.sharedInstance().delegate = self
        
        // Check if we are connected when we foreground
        NotificationCenter.default.addObserver(self, selector: #selector(startScan), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkIfUserLeggedIn), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Authentication
        checkIfUserLeggedIn()
    }
    
    @objc func checkIfUserLeggedIn() {
        checkIfUserLoggedIn(completion: { [weak self] (authStatus) in
            if authStatus {
                self?.startBeaconAndUart()
            } else {
                self?.handleLogout()
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Stop scanning for uart devices
        centralManager?.stopScan()
    }
    
    //MARK: Login/logout
    /// Logs the user out and brings to Login page if logged off, otherwise user stays on Device page
    func checkIfUserLoggedIn(completion: @escaping ((Bool) -> Void)) {
        if !uart_is_connected {
            showWeightSpinner()
            showTempSpinner()
        }
        if !beacon_is_connected {
            showBeaconSpinner()
        }
        showTitleSpinner()
        if let currentUser = Auth.auth().currentUser, let name = currentUser.displayName, let email = currentUser.email {
            //Logged in with Firebase or Google
            let uid = currentUser.uid
            AppDelegate.user = LocalUser(id: uid, name: name, email: email, profileImage: nil)
            hideTitleSpinner()
            navigationItem.title = name
            Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { success in
                print("response from server: ", success)
                if let dict = success.value as? [String: AnyObject], let name = dict["name"] as? String, let email = dict["email"] as? String, let profileImageUrl = dict["profileImageUrl"] as? String {
                    print("user is logged in: ", dict)
                    // TODO: handle creation of user and display profile image
                }
                completion(true)
            })
        } else if FBSDKAccessToken.currentAccessTokenIsActive() {
            //Logged in with Facebook
            guard let accessToken = FBSDKAccessToken.current(), let req = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"email,name"], tokenString: accessToken.tokenString, version: nil, httpMethod: "GET") else {
                completion(false)
                return
            }
            
            req.start { (connection, result, error) in
                if let error = error {
                    print("Facebook error: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Facebook result: \(result.debugDescription)")
                    guard let dict = result as? NSDictionary, let id = dict["id"] as? String, let name = dict["name"] as? String, let email = dict["email"] as? String else { return }
                    self.hideTitleSpinner()
                    self.navigationItem.title = name
                    AppDelegate.user = LocalUser(id: id, name: name, email: email, profileImage: nil)
                    completion(true)
                }
            }
        } else if let shared = GIDSignIn.sharedInstance(), shared.hasAuthInKeychain() {
            completion(false)
        } else {
            //Not logged in
            completion(false)
        }
    }
    
    @objc func handleLogout() {
        disconnectEverything()
        AppDelegate.user = nil
        navigationItem.title = ""
        if let uid = Auth.auth().currentUser?.uid {
            // Logged in with Firebase or Google
            if let shared = GIDSignIn.sharedInstance(), shared.hasAuthInKeychain() {
                // Logout of Google
                shared.signOut()
            }
            // Logout of Firebase
            do {
                try Auth.auth().signOut()
            } catch let logoutError {
                print(logoutError)
            }
        } else if FBSDKAccessToken.currentAccessTokenIsActive() {
            // Logout of Facebook
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
        } else if let shared = GIDSignIn.sharedInstance(), shared.hasAuthInKeychain() {
            // Logout of Google
            shared.signOut()
        } else {
            print("Not logged into anything")
        }
        // Present Login page
        let loginViewController = LoginViewController()
        let navController = UINavigationController(rootViewController: loginViewController)
        DispatchQueue.main.async {
            self.present(navController, animated: true)
        }
    }
    
    /// Disconnect from uart and beacon bluetooth devices
    func disconnectEverything() {
        // Disconnect from UART devices
        guard let peripheral = selectedPeripheral else { return }
        centralManager?.cancelPeripheralConnection(peripheral)
        // Stop ranging all beacons
        if let rangedRegions = locationManager?.rangedRegions as? Set<CLBeaconRegion> {
            rangedRegions.forEach((locationManager?.stopRangingBeacons)!)
        }
    }
    
    @objc func goToSettings() {
        let settingsViewController = SettingsViewController()
        let navController = UINavigationController(rootViewController: settingsViewController)
        DispatchQueue.main.async {
            self.present(navController, animated: true, completion: nil)
        }
    }
    
    /// Logo on Device page
    lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "GUARDIAN ANGEL - LOGO 2 - white/")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        
        return imageView
    }()
    
    let title_loadingView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    let temp_loadingView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    let beacon_loadingView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    let weight_loadingView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    
    /// Label that is shown under the logo
    let logoTextLabelField: UILabel = {
        let tf = UILabel()
        tf.text = "Guardian Angel"
        tf.textColor = UIColor.white
        tf.textAlignment = .center
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    /// Contains all of the labels that shows the Bluetooth information
    let inputsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    /// Temp label
    let tempTextLabelField: UILabel = {
        let tf = UILabel()
        tf.text = "Temperature:"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    /// Proximity label
    let beaconTextLabelField: UILabel = {
        let tf = UILabel()
        tf.text = "Proximity from baby:"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    /// Weight label
    let activeTextLabelField: UILabel = {
        let tf = UILabel()
        tf.text = "Baby in seat?"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    /// Shows status of the temperature readings
    let
    tempStatusLabelField: UILabel = {
        let tf = UILabel()
        tf.text = "Not Connected"
        tf.textAlignment = .right
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    /// Shows status of the beacon readings
    let beaconStatusLabelField: UILabel = {
        let tf = UILabel()
        tf.text = "Not Connected"
        tf.textAlignment = .right
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    /// Shows status of the weight readings
    let activeStatusLabelField: UILabel = {
        let tf = UILabel()
        tf.text = "No"
        tf.textAlignment = .right
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    /// Seperator Field 1
    let tempSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.rgb(red: 220, green: 91, blue: 151)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Seperator Field 2
    let weightSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.rgb(red: 220, green: 91, blue: 151)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Sets up the UI for the Device page
    func setupDeviceContainerView() {
        // add subviews to view
        view.addSubview(logoImageView)
        view.addSubview(inputsContainerView)

        // Setup constraints of logo image view
        logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive=true
        logoImageView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 37).isActive=true
        logoImageView.widthAnchor.constraint(equalToConstant: 100).isActive=true
        logoImageView.heightAnchor.constraint(equalToConstant: 100).isActive=true
        
        //setup constraints of container view
        inputsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive=true
        inputsContainerView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 30).isActive=true
        inputsContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive=true
        inputsContainerView.heightAnchor.constraint(equalToConstant: 150).isActive=true
    
        // add text fields to container view
        inputsContainerView.addSubview(tempTextLabelField)
        inputsContainerView.addSubview(activeTextLabelField)
        inputsContainerView.addSubview(beaconTextLabelField)
        
        // add status labels to container view
        inputsContainerView.addSubview(tempStatusLabelField)
        inputsContainerView.addSubview(activeStatusLabelField)
        inputsContainerView.addSubview(beaconStatusLabelField)
        
        // add seperator views to container view
        inputsContainerView.addSubview(tempSeperatorView)
        inputsContainerView.addSubview(weightSeperatorView)
        
        // add loading views to container view
        inputsContainerView.addSubview(temp_loadingView)
        inputsContainerView.addSubview(beacon_loadingView)
        inputsContainerView.addSubview(weight_loadingView)
        
        //setup constraints for name text field
        tempTextLabelField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive=true
        tempTextLabelField.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive=true
        tempTextLabelField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive=true
        tempTextLabelField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3).isActive=true
        //setup constraints for beacon text field
        beaconTextLabelField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive=true
        beaconTextLabelField.topAnchor.constraint(equalTo: tempTextLabelField.bottomAnchor).isActive=true
        beaconTextLabelField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive=true
        beaconTextLabelField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3).isActive=true
        //setup constraints for weight text field
        activeTextLabelField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive=true
        activeTextLabelField.topAnchor.constraint(equalTo: beaconTextLabelField.bottomAnchor).isActive=true
        activeTextLabelField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive=true
        activeTextLabelField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3).isActive=true
        
        //setup constraints for temp status text field
        tempStatusLabelField.rightAnchor.constraint(equalTo: inputsContainerView.rightAnchor, constant: -12).isActive=true
        tempStatusLabelField.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive=true
        tempStatusLabelField.widthAnchor.constraint(equalToConstant: 120).isActive=true
        tempStatusLabelField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3).isActive=true
        //setup constraints for beacon status text field
        beaconStatusLabelField.rightAnchor.constraint(equalTo: inputsContainerView.rightAnchor, constant: -12).isActive=true
        beaconStatusLabelField.topAnchor.constraint(equalTo: tempStatusLabelField.bottomAnchor).isActive=true
        beaconStatusLabelField.widthAnchor.constraint(equalToConstant: 120).isActive=true
        beaconStatusLabelField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3).isActive=true
        //setup constraints for weight status text field
        activeStatusLabelField.rightAnchor.constraint(equalTo: inputsContainerView.rightAnchor, constant: -12).isActive=true
        activeStatusLabelField.topAnchor.constraint(equalTo: beaconStatusLabelField.bottomAnchor).isActive=true
        activeStatusLabelField.widthAnchor.constraint(equalToConstant: 120).isActive=true
        activeStatusLabelField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3).isActive=true
        
        //setup constarints for temp loading view
        temp_loadingView.translatesAutoresizingMaskIntoConstraints = false
        temp_loadingView.rightAnchor.constraint(equalTo: inputsContainerView.rightAnchor, constant: 35).isActive=true
        temp_loadingView.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive=true
        temp_loadingView.widthAnchor.constraint(equalToConstant: 120).isActive=true
        temp_loadingView.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3).isActive=true
        //setup constarints for beacon loading view
        beacon_loadingView.translatesAutoresizingMaskIntoConstraints = false
        beacon_loadingView.rightAnchor.constraint(equalTo: inputsContainerView.rightAnchor, constant: 35).isActive=true
        beacon_loadingView.topAnchor.constraint(equalTo: tempStatusLabelField.bottomAnchor).isActive=true
        beacon_loadingView.widthAnchor.constraint(equalToConstant: 120).isActive=true
        beacon_loadingView.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3).isActive=true
        //setup constarints for weight loading view
        weight_loadingView.translatesAutoresizingMaskIntoConstraints = false
        weight_loadingView.rightAnchor.constraint(equalTo: inputsContainerView.rightAnchor, constant: 35).isActive=true
        weight_loadingView.topAnchor.constraint(equalTo: beaconStatusLabelField.bottomAnchor).isActive=true
        weight_loadingView.widthAnchor.constraint(equalToConstant: 120).isActive=true
        weight_loadingView.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3).isActive=true
        
        //setup constraints for temp seperator field
        tempSeperatorView.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive=true
        tempSeperatorView.topAnchor.constraint(equalTo: tempTextLabelField.bottomAnchor).isActive=true
        tempSeperatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive=true
        tempSeperatorView.heightAnchor.constraint(equalToConstant: 1).isActive=true
        //setup constraints for weight seperator field
        weightSeperatorView.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive=true
        weightSeperatorView.topAnchor.constraint(equalTo: beaconTextLabelField.bottomAnchor).isActive=true
        weightSeperatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive=true
        weightSeperatorView.heightAnchor.constraint(equalToConstant: 1).isActive=true
    }
    
    // MARK: Loading view functions
    func showTitleSpinner() {
        if !title_loadingView.isAnimating {
            self.navigationItem.titleView = title_loadingView
            title_loadingView.startAnimating()
        }
    }
    
    func hideTitleSpinner() {
        if title_loadingView.isAnimating {
            title_loadingView.stopAnimating()
            self.navigationItem.titleView = nil
        }
    }
    
    func showTempSpinner() {
        if !temp_loadingView.isAnimating && !tempStatusLabelField.isHidden {
            temp_loadingView.startAnimating()
            tempStatusLabelField.isHidden = true
        }
    }
    
    func hideTempSpinner()  {
        if temp_loadingView.isAnimating && tempStatusLabelField.isHidden {
            temp_loadingView.stopAnimating()
            tempStatusLabelField.isHidden = false
        }
    }
    
    func showBeaconSpinner() {
        if !beacon_loadingView.isAnimating && !beaconStatusLabelField.isHidden {
            beacon_loadingView.startAnimating()
            beaconStatusLabelField.isHidden = true
        }
    }
    
    func hideBeaconSpinner() {
        if beacon_loadingView.isAnimating && beaconStatusLabelField.isHidden {
            beacon_loadingView.stopAnimating()
            beaconStatusLabelField.isHidden = false
        }
    }
    
    func showWeightSpinner() {
        if !weight_loadingView.isAnimating && !activeStatusLabelField.isHidden {
            weight_loadingView.startAnimating()
            activeStatusLabelField.isHidden = true
        }
    }
    
    func hideWeightSpinner() {
        if weight_loadingView.isAnimating && activeStatusLabelField.isHidden {
            weight_loadingView.stopAnimating()
            activeStatusLabelField.isHidden = false
        }
    }
}

extension DeviceViewController: GIDSignInDelegate {
    // Google sign-in delegate methods
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        print("Successfully logged into Google", user)
        
        if error != nil {
            print("Error signing into Google: ", error)
            return
        }
        guard let idToken = user.authentication.idToken else { return }
        guard let accessToken = user.authentication.accessToken else { return }
        let credentials = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        Auth.auth().signIn(with: credentials, completion: { (user, error) in
            if let err = error {
                print("Failed to create a Firebase User with Google account: ", err)
                return
            }
            
            guard let uid = user?.uid, let name = user?.displayName, let email = user?.email else { return }
            AppDelegate.user = LocalUser(id: uid, name: name, email: email, profileImage: nil)
            self.navigationItem.title = name
        })
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
              withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
}
