//
//  GPSViewController.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 7/3/19.
//  Copyright © 2019 Guardian Angel. All rights reserved.
//

import UIKit
import WhatsNewKit
import MapKit
import FirebaseDatabase
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

class GPSViewController: UIViewController, CLLocationManagerDelegate, SettingsDelegate {
    var locationManager: CLLocationManager?
    let mapView = MKMapView()
    let regionRadius: CLLocationDistance = 4000
    var actionButton : ActionButton!
    var isLoggedIn: AuthState = .loggedOut
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup UI
        view.backgroundColor = standardColor

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(goToSettings))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Info", style: .plain, target: self, action: #selector(goToGPSInfoView))
        
        setupMap()
        setupLocationButtons()
        // TODO: setup gps tracking
        NotificationCenter.default.addObserver(self, selector: #selector(determineCushionLocation), name: UIApplication.willEnterForegroundNotification
            , object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkIfUserLoggedIn()
    }
    
    // MARK: Setup UI
    @objc func goToSettings() {
        let settingsViewController = SettingsViewController()
        settingsViewController.delegate = self
        let navController = UINavigationController(rootViewController: settingsViewController)
        DispatchQueue.main.async {
            self.present(navController, animated: true, completion: nil)
        }
    }
    
    private func setupMap() {
        // Setup UI properties
        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.showsUserLocation = true
        mapView.showsScale = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
    
        view.addSubview(mapView)
        
        // Setup UI constraints
        mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive=true
        mapView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive=true
        mapView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive=true
    }
    
    // MARK: Authentication Methods
    private func checkIfUserLoggedIn() {
        if let user = AppDelegate.user {
            self.navigationItem.title = user.name
            return
        }
        isLoggedIn = .loggingIn
        checkIfUserLoggedIn(completion: { [weak self] (authStatus) in
            self?.isLoggedIn = authStatus
            if authStatus == .loggedIn {
                self?.determineCushionLocation()
            } else {
                self?.navigationItem.title = "Not Logged In"
                self?.hideTitleSpinner()
                self?.logout()
            }
        })
    }
    
    private func checkIfUserLoggedIn(completion: @escaping ((AuthState) -> Void)) {
        if let currentUser = Auth.auth().currentUser, let name = currentUser.displayName, let email = currentUser.email {
            //Logged in with Firebase or Google
            // Setup user
            let uid = currentUser.uid
            AppDelegate.user = LocalUser(id: uid, name: name, email: email)
            // TODO: Figure out what is being done here
            Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { success in
                print("response from server: ", success)
                if let dict = success.value as? [String: AnyObject] {
                    print("user is logged in: ", dict)
                    // TODO: handle creation of user
                }
                completion(.loggedIn)
            })
        } else if AccessToken.isCurrentAccessTokenActive {
            guard let accessToken = AccessToken.current else {
                completion(.loggedOut)
                return
            }
            //Logged in with Facebook
            let req = GraphRequest(graphPath: "me", parameters: ["fields":"email,name"], tokenString: accessToken.tokenString, version: nil, httpMethod: HTTPMethod(rawValue: "GET"))
            
            req.start { [weak self] (connection, result, error) in
                if let error = error {
                    print("Facebook error: \(error.localizedDescription)")
                    completion(.loggedOut)
                } else {
                    print("Facebook result: \(result.debugDescription)")
                    guard let dict = result as? NSDictionary, let id = dict["id"] as? String, let name = dict["name"] as? String, let email = dict["email"] as? String else { return }
                    // Setup UI
                    self?.navigationItem.title = name
                    self?.hideTitleSpinner()
                    // Setup user
                    AppDelegate.user = LocalUser(id: id, name: name, email: email)
                    completion(.loggedIn)
                }
            }
        } else if let shared = GIDSignIn.sharedInstance(), shared.hasPreviousSignIn() {
            completion(.loggedOut)
        } else {
            //Not logged in
            completion(.loggedOut)
        }
    }
    
    @objc func logout() {
        disconnectDevice()
        AppDelegate.user = nil
        presentLoginPage()
        if Auth.auth().currentUser != nil {
            // Logged in with Firebase or Google
            if let shared = GIDSignIn.sharedInstance(), shared.hasPreviousSignIn() {
                // Logout of Google
                shared.signOut()
            }
            // Logout of Firebase
            do {
                try Auth.auth().signOut()
            } catch let logoutError {
                print(logoutError)
            }
        } else if AccessToken.isCurrentAccessTokenActive {
            // Logout of Facebook
            let loginManager = LoginManager()
            loginManager.logOut()
        } else if let shared = GIDSignIn.sharedInstance(), shared.hasPreviousSignIn() {
            // Logout of Google
            shared.signOut()
        }
    }
    
    private func presentLoginPage() {
        let loginViewController = LoginViewController()
        loginViewController.loginDelegate = self
        let navController = UINavigationController(rootViewController: loginViewController)
        DispatchQueue.main.async {
            self.present(navController, animated: true)
        }
    }
    
    // MARK: Settings Delegate Methods
    // TODO: have these methods be optional to implement?
    func backgroundScan() {}
    
    func disconnectDevice() {}
    

    
    // MARK: Loading view functions
    func showTitleSpinner() {
        // TODO
//        if !title_loadingView.isAnimating {
//            self.navigationItem.titleView = title_loadingView
//            title_loadingView.startAnimating()
//        }
    }
    
    func hideTitleSpinner() {
        // TODO
//        if title_loadingView.isAnimating {
//            title_loadingView.stopAnimating()
//            self.navigationItem.titleView = nil
//        }
    }
    
    // MARK: Location Helper Methods
    // TODO: make this work
    private func setupLocationButtons() {
        // Setup cushion location button
        let cushionLocationButton = UIButton(type: .custom)
        cushionLocationButton.frame = CGRect(x: 200, y: 200, width: 50, height: 50)
        cushionLocationButton.layer.cornerRadius = 0.5 * cushionLocationButton.bounds.size.width
        // setup image for button
        var image1 = UIImage(named: "gps")?.maskWithColor(color: standardColor)
        if #available(iOS 13.0, *) {
            // If we're in dark mode, change the button image color to white
            if UITraitCollection.current.userInterfaceStyle == .dark {
                image1 = image1?.maskWithColor(color: UIColor.white)
            }
        }
        cushionLocationButton.setImage(image1, for: UIControl.State())
        cushionLocationButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        cushionLocationButton.isUserInteractionEnabled = true
        cushionLocationButton.translatesAutoresizingMaskIntoConstraints = false
        cushionLocationButton.addTarget(self, action: #selector(cushionLocation), for: .touchUpInside)
        // add cushion location button to view
        self.mapView.addSubview(cushionLocationButton)
        // add constraints for location button view
        cushionLocationButton.centerXAnchor.constraint(equalTo: self.mapView.rightAnchor, constant: -50).isActive=true
        cushionLocationButton.centerYAnchor.constraint(equalTo: self.mapView.topAnchor, constant: 50).isActive=true
        
        // Setup current location button
        let currentLocationButton = UIButton(type: .custom)
        currentLocationButton.frame = CGRect(x: 200, y: 200, width: 50, height: 50)
        currentLocationButton.layer.cornerRadius = 0.5 * currentLocationButton.bounds.size.width
        // setup image for button
        var image2 = UIImage(named: "location.fill")?.maskWithColor(color: standardColor)
        if #available(iOS 13.0, *) {
            // If we're in dark mode, change the button image color to white
            if UITraitCollection.current.userInterfaceStyle == .dark {
                image2 = image2?.maskWithColor(color: UIColor.white)
            }
        }
        currentLocationButton.setImage(image2, for: UIControl.State())
        currentLocationButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        currentLocationButton.isUserInteractionEnabled = true
        currentLocationButton.translatesAutoresizingMaskIntoConstraints = false
        currentLocationButton.addTarget(self, action: #selector(currentLocation), for: .touchUpInside)
        // add current location button to view
        self.mapView.addSubview(currentLocationButton)
        // add constraints for location button view
        currentLocationButton.centerXAnchor.constraint(equalTo: self.mapView.rightAnchor, constant: -50).isActive=true
        currentLocationButton.centerYAnchor.constraint(equalTo: self.mapView.topAnchor, constant: 100).isActive=true

        // Setup cushion text view
        let cushionLocationLabel = UILabel()
        cushionLocationLabel.translatesAutoresizingMaskIntoConstraints = false
        cushionLocationLabel.text = "Cushion Location"
        cushionLocationLabel.textAlignment = .center
        cushionLocationLabel.textColor = .white
        cushionLocationLabel.backgroundColor = standardColor
        cushionLocationLabel.clipsToBounds = true
        cushionLocationLabel.layer.cornerRadius = 10.0
        cushionLocationLabel.font = UIFont(name: "HelveticaNeue-Medium", size: 14)
        // add touch to text view
        let tapGesture1 = UITapGestureRecognizer(target: self, action: #selector(cushionLocation))
        cushionLocationLabel.addGestureRecognizer(tapGesture1)
        // add to view
        self.mapView.addSubview(cushionLocationLabel)
        // setup constraints
        cushionLocationLabel.heightAnchor.constraint(equalToConstant: 30).isActive=true
        cushionLocationLabel.widthAnchor.constraint(equalToConstant: 130).isActive=true
        cushionLocationLabel.rightAnchor.constraint(equalTo: currentLocationButton.leftAnchor).isActive=true
        cushionLocationLabel.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 30).isActive=true
        
        // Setup current location text view
        let currentLocationLabel = UILabel()
        currentLocationLabel.translatesAutoresizingMaskIntoConstraints = false
        currentLocationLabel.text = "Your Location"
        currentLocationLabel.textAlignment = .center
        currentLocationLabel.textColor = .white
        currentLocationLabel.backgroundColor = standardColor
        currentLocationLabel.clipsToBounds = true
        currentLocationLabel.layer.cornerRadius = 10.0
        currentLocationLabel.font = UIFont(name: "HelveticaNeue-Medium", size: 14)
        // add touch to text view
        let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector(currentLocation))
        currentLocationLabel.addGestureRecognizer(tapGesture2)
        // add to view
        self.mapView.addSubview(currentLocationLabel)
        // setup constraints
        currentLocationLabel.heightAnchor.constraint(equalToConstant: 30).isActive=true
        currentLocationLabel.widthAnchor.constraint(equalToConstant: 110).isActive=true
        currentLocationLabel.rightAnchor.constraint(equalTo: currentLocationButton.leftAnchor, constant: -10).isActive=true
        currentLocationLabel.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 80).isActive=true
    }
    
    @objc func currentLocation() {
        print("your location")
    }
    
    @objc func cushionLocation() {
        print("cushion location")
    }
    
    @objc func determineCushionLocation() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager?.startUpdatingLocation()
        }
    }
    // MARK: Location Manager Delegate Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes.
        manager.stopUpdatingLocation()
        
        // Setup region
        let coordinateRegion = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        // Setup annotation
        let annotation = MKPointAnnotation()
        annotation.title = "Guardian Angel Cushion"
        annotation.coordinate = userLocation.coordinate
        mapView.addAnnotation(annotation)
        mapView.mapType = .standard
        
        print("user latitude = \(userLocation.coordinate.latitude)")
        print("user longitude = \(userLocation.coordinate.longitude)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // TODO: show error message
    }
    
}
// MARK: Google SignIn Delegate Methods
extension GPSViewController: GIDSignInDelegate {
    // Google sign-in delegate methods
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        print("Successfully logged into Google", user.debugDescription)
        
        if error != nil {
            print("Error signing into Google: ", error.debugDescription)
            return
        }
        
        guard let profile = user?.profile, let id = user.userID else { return }
        let name = profile.name ?? "", email = profile.email
        executeOnMainThread { [weak self] in
            // Setup UI
            self?.navigationItem.title = name
            self?.hideTitleSpinner()
        }
        // Setup user
        AppDelegate.user = LocalUser(id: id, name: name, email: email)
        guard let idToken = user.authentication.idToken else { return }
        guard let accessToken = user.authentication.accessToken else { return }
        let credentials = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        Auth.auth().signIn(with: credentials, completion: { (result, error) in
            if let err = error {
                // TODO: handle error
                print("Failed to create a Firebase User with Google account: ", err)
                return
            }
        })
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
              withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // TODO: do something
    }
}
// MARK: Login Delegate Method
extension GPSViewController: LoginDelegate {
    func setTitle(_ title: String) {
        self.navigationItem.title = title
    }
}
