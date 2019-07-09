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

class GPSViewController: UIViewController, CLLocationManagerDelegate {
    var locationManager:CLLocationManager?
    let mapView = MKMapView()
    let regionRadius: CLLocationDistance = 4000
    var actionButton : ActionButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup UI
        title = AppDelegate.user?.name
        view.backgroundColor = standardColor

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(goToSettings))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action:#selector(logout))
        
        setupMap()
        setupLocationButtons()
        
        NotificationCenter.default.addObserver(self, selector: #selector(determineMyCurrentLocation), name: UIApplication.willEnterForegroundNotification
            , object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkIfUserLoggedIn()
    }
    
    private func checkIfUserLoggedIn() {
        checkIfUserLoggedIn(completion: { [weak self] (authStatus) in
            if authStatus {
                self?.determineMyCurrentLocation()
            } else {
                self?.logout()
            }
        })
    }
    
    private func checkIfUserLoggedIn(completion: @escaping ((Bool) -> Void)) {
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
                completion(true)
            })
        } else if AccessToken.isCurrentAccessTokenActive {
            guard let accessToken = AccessToken.current else {
                completion(false)
                return
            }
            //Logged in with Facebook
            let req = GraphRequest(graphPath: "me", parameters: ["fields":"email,name"], tokenString: accessToken.tokenString, version: nil, httpMethod: HTTPMethod(rawValue: "GET"))
            
            req.start { [weak self] (connection, result, error) in
                if let error = error {
                    print("Facebook error: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Facebook result: \(result.debugDescription)")
                    guard let dict = result as? NSDictionary, let id = dict["id"] as? String, let name = dict["name"] as? String, let email = dict["email"] as? String else { return }
                    // Setup UI
                    self?.navigationItem.title = name
                    self?.hideTitleSpinner()
                    // Setup user
                    AppDelegate.user = LocalUser(id: id, name: name, email: email)
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
    
    @objc func logout() {
//        disconnectEverything()
        AppDelegate.user = nil
        presentLoginPage()
        if Auth.auth().currentUser != nil {
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
        } else if AccessToken.isCurrentAccessTokenActive {
            // Logout of Facebook
            let loginManager = LoginManager()
            loginManager.logOut()
        } else if let shared = GIDSignIn.sharedInstance(), shared.hasAuthInKeychain() {
            // Logout of Google
            shared.signOut()
        }
    }
    
    private func presentLoginPage() {
        let loginViewController = LoginViewController()
        let navController = UINavigationController(rootViewController: loginViewController)
        DispatchQueue.main.async {
            self.present(navController, animated: true)
        }
    }
    
    @objc func goToSettings() {
        let settingsViewController = SettingsViewController()
        let navController = UINavigationController(rootViewController: settingsViewController)
        DispatchQueue.main.async {
            self.present(navController, animated: true, completion: nil)
        }
    }
    
    private let infoButton: UIButton = {
        let infoButton = UIButton(type: .infoDark)
        infoButton.addTarget(self, action: #selector(showGPSInfoView), for: .touchUpInside)
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        return infoButton
    }()
    
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
    
    // TODO: make this work
    private func setupLocationButtons() {
        let currentLocationButton = ActionButtonItem(title: "Go to Current Location", image: UIImage(named: "refreshButton"))
        currentLocationButton.action = { item in self.view.backgroundColor = UIColor.red }
        let cushionLocationButton = ActionButtonItem(title: "Go to Cushion Location", image: UIImage(named: "gear"))
        cushionLocationButton.action = { item in self.view.backgroundColor = UIColor.blue }
        actionButton = ActionButton(attachedToView: mapView, items: [currentLocationButton, cushionLocationButton])
        actionButton.setTitle("+", forState: UIControl.State())
        actionButton.backgroundColor = UIColor(red: 238.0/255.0, green: 130.0/255.0, blue: 130.0/255.0, alpha: 1)
        actionButton.action = { button in button.toggleMenu()}
    }
    
    @objc func determineMyCurrentLocation() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager?.startUpdatingLocation()
        }
    }
    
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

    @objc func showGPSInfoView() {
        let whatsNew = WhatsNew(
            title: "Information about GPS",
            items: [
                WhatsNew.Item(
                    title: "Temperature Section:",
                    subtitle: "The temperature calculated by the smart cushion",
                    image: UIImage(named: "temp")
                ),
                WhatsNew.Item(
                    title: "Proximity from Cushion Section:",
                    subtitle: "Provides information about the proximity of the user from the smart cushion",
                    image: UIImage(named: "proximity")
                ),
                WhatsNew.Item(
                    title: "Device Active Section:",
                    subtitle: "Determines if weight is detected on cushion. You can only receive notifications if the device is active",
                    image: UIImage(named: "setup")
                ),
                WhatsNew.Item(
                    title: "Questions?",
                    subtitle: "Email us at support@guardianangelcushion.com",
                    image: UIImage(named: "question")
                )
            ]
        )
        
        let myTheme = WhatsNewViewController.Theme { configuration in
            configuration.titleView.titleColor = .white
            configuration.backgroundColor = standardColor
            configuration.itemsView.titleFont = .boldSystemFont(ofSize: 22)
            configuration.itemsView.titleColor = .white
            configuration.itemsView.subtitleFont = .systemFont(ofSize: 13.2)
            configuration.itemsView.subtitleColor = .white
            configuration.completionButton.title = "Go Back"
            configuration.completionButton.backgroundColor = .white
            configuration.completionButton.titleColor = standardColor
        }
        
        let configuration = WhatsNewViewController.Configuration(
            theme: myTheme
        )
        
        let whatsNewViewController = WhatsNewViewController(
            whatsNew: whatsNew,
            configuration: configuration
        )
        
        present(whatsNewViewController, animated: true)
    }
}
