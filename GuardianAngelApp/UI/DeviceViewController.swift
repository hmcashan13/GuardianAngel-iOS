//
//  DeviceViewController.swift
//  GuardianAngel
//
//  Created by Hudson Mcashan on 2/1/18.
//  Copyright © 2018 Hudson Mcashan. All rights reserved.
//

import UIKit
import CoreBluetooth
import UserNotifications
import CoreLocation
import WhatsNewKit

class DeviceViewController: UIViewController {
    // Beacon properties
    let beaconRegion = CLBeaconRegion(
        proximityUUID: UUID(uuidString:"01122334-4556-6778-899A-ABBCCDDEEFF0")!,
        major: 0,
        minor: 0,
        identifier: "Guardian")
    let beaconRegion2 = CLBeaconRegion(
        proximityUUID: UUID(uuidString:"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!,
        major: 0,
        minor: 0,
        identifier: "Guardian")
    var proximity = notConnected
    var isBeaconConnected: Bool = false
    var locationManager: CLLocationManager?
    
    // UART properties
    let UART_UUID = UUID(uuidString: "8519BF04-6C36-4B4A-4182-A2764CE2E05A")
    let UART_UUID2 = UUID(uuidString: "F0B6C05F-15A0-9F38-BBD9-5E117CF7DC7A")
    var rxCharacteristic : CBCharacteristic?
    var isUartConnected: Bool = false
    var centralManager: CBCentralManager?
    var selectedPeripheral: CBPeripheral?
    var isBabyInSeat: Bool = false
    var maxTemp: Int = 80
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup UI
        view.backgroundColor = UIColor(displayP3Red: 0.7, green: 0.4, blue: 1.0, alpha: 1.0)
        
        setupDeviceContainerView()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(goToSettings))
        navigationItem.rightBarButtonItem?.tintColor = UIColor.black
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
        let infoBarButtonItem = UIBarButtonItem(customView: infoButton)
        navigationItem.leftBarButtonItem = infoBarButtonItem
        
        showTempSpinner()
        showWeightSpinner()
        showBeaconSpinner()
        setTitleConnecting()
        
        // Setup Notifications
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        setupNotification()
 
        // Setup UART
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // Setup Beacon
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false
        locationManager?.requestWhenInUseAuthorization()
        
        // Check if we are connected when we foreground
        NotificationCenter.default.addObserver(self, selector: #selector(foregroundScan), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        // Connect to cushion
        startBeaconAndUart()
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
    // MARK: UI properties and setup
    /// Logo on Device page
    lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "GUARDIAN ANGEL - LOGO 2 - white/")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        
        return imageView
    }()
    
    // Loading views
    let title_loadingView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    let temp_loadingView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    let beacon_loadingView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    let weight_loadingView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    
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
        tf.text = "Proximity from Cushion:"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    /// Weight label
    let activeTextLabelField: UILabel = {
        let tf = UILabel()
        tf.text = "Device Active?"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    /// Shows status of the temperature readings
    let
    tempStatusLabelField: UILabel = {
        let tf = UILabel()
        tf.text = notConnected
        tf.textAlignment = .right
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    /// Shows status of the beacon readings
    let beaconStatusLabelField: UILabel = {
        let tf = UILabel()
        tf.text = notConnected
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
        view.backgroundColor = UIColor(displayP3Red: 0.7, green: 0.4, blue: 1.0, alpha: 1.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Seperator Field 2
    let weightSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(displayP3Red: 0.7, green: 0.4, blue: 1.0, alpha: 1.0)
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
            let timer = CustomTimer(timeInterval: 20) {
                self.hideTempSpinner()
            }
            timer.start()
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
            let timer = CustomTimer(timeInterval: 20) {
                self.hideBeaconSpinner()
            }
            timer.start()
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
            let timer = CustomTimer(timeInterval: 20) {
                self.hideWeightSpinner()
            }
            timer.start()
        }
    }
    
    func hideWeightSpinner() {
        if weight_loadingView.isAnimating && activeStatusLabelField.isHidden {
            weight_loadingView.stopAnimating()
            activeStatusLabelField.isHidden = false
        }
    }
    
    func setTitleConnected() {
        navigationItem.title = "Connected"
    }
    
    func setTitleDisconnected() {
        navigationItem.title = "Disconnected"
    }
    
    func setTitleConnecting() {
        navigationItem.title = "Connecting"
    }
    
    @objc func showInfo() {
        let whatsNew = WhatsNew(
            title: "Information about the App",
            items: [
                WhatsNew.Item(
                    title: "Temperature Section:",
                    subtitle: "The temperature calculated by the smart cushion",
                    image: UIImage(named: "temp copy")
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
            configuration.backgroundColor = UIColor(displayP3Red: 0.7, green: 0.4, blue: 1.0, alpha: 1.0)
            configuration.itemsView.titleFont = .boldSystemFont(ofSize: 22)
            configuration.itemsView.titleColor = .white
            configuration.itemsView.subtitleFont = .systemFont(ofSize: 13.2)
            configuration.itemsView.subtitleColor = .white
            configuration.completionButton.title = "Go Back"
            configuration.completionButton.backgroundColor = .white
            configuration.completionButton.titleColor = UIColor(displayP3Red: 0.7, green: 0.4, blue: 1.0, alpha: 1.0)
        }
        
        let configuration = WhatsNewViewController.Configuration(
            theme: myTheme
        )
        
        let whatsNewViewController = WhatsNewViewController(
            whatsNew: whatsNew,
            configuration: configuration
        )
        
        self.present(whatsNewViewController, animated: true)
    }
}
