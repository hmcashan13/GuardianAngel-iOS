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
    let beaconRegion: CLBeaconRegion = CLBeaconRegion(
        proximityUUID: UUID(uuidString:"01122334-4556-6778-899A-ABBCCDDEEFF0")!,
        major: 0,
        minor: 0,
        identifier: "Guardian")
    let beaconRegion2: CLBeaconRegion = CLBeaconRegion(
        proximityUUID: UUID(uuidString:"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!,
        major: 0,
        minor: 0,
        identifier: "Guardian")
    var proximity: String = notConnected
    var isBeaconConnected: Bool = false
    var locationManager: CLLocationManager?
    
    // UART properties
    enum ConnectionState {
        case connected
        case notConnected
        case connecting
        case tempNotActive
    }
    let UART_UUID: UUID = UUID(uuidString: "8519BF04-6C36-4B4A-4182-A2764CE2E05A")!
    let UART_UUID2: UUID = UUID(uuidString: "F0B6C05F-15A0-9F38-BBD9-5E117CF7DC7A")!
    var rxCharacteristic: CBCharacteristic?
    var connectionState:ConnectionState = .notConnected
    var centralManager: CBCentralManager?
    var selectedPeripheral: CBPeripheral?
    var isWeightDetected: Bool = false
    var maxTemp: Int = 80
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup UI
        view.backgroundColor = standardColor
        
        setupDeviceContainerView()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(goToSettings))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout))
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if connectionState == .notConnected {
            backgroundScan()
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
    
    @objc func logout() {
        //TODO: bring back auth logic
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
    private let title_loadingView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    private let temp_loadingView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    private let beacon_loadingView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    private let weight_loadingView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    
    /// Contains all of the labels that shows the Bluetooth information
    private let inputsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    /// Cushion Identifier Label
    private let deviceIdentifierLabel: UILabel = {
        let tf = UILabel()
        tf.text = "Cushion 1"
        tf.font = UIFont.boldSystemFont(ofSize: 18)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let infoButton: UIButton = {
        let infoButton = UIButton(type: .infoDark)
        infoButton.addTarget(self, action: #selector(showDeviceInfo), for: .touchUpInside)
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        return infoButton
    }()
    
    /// Temp label
    private let tempTextLabel: UILabel = {
        let tf = UILabel()
        tf.text = "Temperature:"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    /// Proximity label
    private let beaconTextLabel: UILabel = {
        let tf = UILabel()
        tf.text = "Proximity from Cushion:"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    /// Weight label
    private let activeTextLabel: UILabel = {
        let tf = UILabel()
        tf.text = "Device Active?"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    /// Shows status of the temperature readings
    private let tempStatusLabel: UILabel = {
        let tf = UILabel()
        tf.text = notConnected
        tf.textAlignment = .right
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    /// Shows status of the beacon readings
    private let beaconStatusLabel: UILabel = {
        let tf = UILabel()
        tf.text = notConnected
        tf.textAlignment = .right
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    /// Shows status of the weight readings
    private let activeStatusLabel: UILabel = {
        let tf = UILabel()
        tf.text = no
        tf.textAlignment = .right
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    /// Seperator Field 1
    private let identifierSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(displayP3Red: 0.7, green: 0.4, blue: 1.0, alpha: 1.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Seperator Field 2
    private let tempSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(displayP3Red: 0.7, green: 0.4, blue: 1.0, alpha: 1.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Seperator Field 3
    private let weightSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(displayP3Red: 0.7, green: 0.4, blue: 1.0, alpha: 1.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Sets up the UI for the Device page
    private func setupDeviceContainerView() {
        // add subviews to view
        view.addSubview(logoImageView)
        view.addSubview(inputsContainerView)

        // Setup constraints of logo image view
        logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive=true
        logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor , constant: 10).isActive=true
        logoImageView.widthAnchor.constraint(equalToConstant: 90).isActive=true
        logoImageView.heightAnchor.constraint(equalToConstant: 90).isActive=true
        
        //setup constraints of container view
        inputsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive=true
        inputsContainerView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20).isActive=true
        inputsContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive=true
        inputsContainerView.heightAnchor.constraint(equalToConstant: 180).isActive=true
    
        // add identifier and info fields {
        inputsContainerView.addSubview(deviceIdentifierLabel)
        inputsContainerView.addSubview(infoButton)
        
        // add text labels to container view
        inputsContainerView.addSubview(tempTextLabel)
        inputsContainerView.addSubview(activeTextLabel)
        inputsContainerView.addSubview(beaconTextLabel)
        
        // add status labels to container view
        inputsContainerView.addSubview(tempStatusLabel)
        inputsContainerView.addSubview(activeStatusLabel)
        inputsContainerView.addSubview(beaconStatusLabel)
        
        // add seperator views to container view
        inputsContainerView.addSubview(identifierSeperatorView)
        inputsContainerView.addSubview(tempSeperatorView)
        inputsContainerView.addSubview(weightSeperatorView)
        
        // add loading views to container view
        inputsContainerView.addSubview(temp_loadingView)
        inputsContainerView.addSubview(beacon_loadingView)
        inputsContainerView.addSubview(weight_loadingView)
        
        // setup constraints for identifier label
        deviceIdentifierLabel.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive=true
        deviceIdentifierLabel.topAnchor.constraint(equalTo: inputsContainerView.topAnchor, constant: 2).isActive=true
        deviceIdentifierLabel.widthAnchor.constraint(equalToConstant: 100).isActive=true
        deviceIdentifierLabel.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/4).isActive=true
        
        // setup constraints for text labels
        tempTextLabel.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive=true
        tempTextLabel.topAnchor.constraint(equalTo: deviceIdentifierLabel.bottomAnchor).isActive=true
        tempTextLabel.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive=true
        tempTextLabel.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/4).isActive=true
        
        beaconTextLabel.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive=true
        beaconTextLabel.topAnchor.constraint(equalTo: tempTextLabel.bottomAnchor).isActive=true
        beaconTextLabel.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive=true
        beaconTextLabel.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/4).isActive=true
        
        activeTextLabel.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive=true
        activeTextLabel.topAnchor.constraint(equalTo: beaconTextLabel.bottomAnchor).isActive=true
        activeTextLabel.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive=true
        activeTextLabel.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/4).isActive=true
        
        // setup constraints for info button
        infoButton.rightAnchor.constraint(equalTo: inputsContainerView.rightAnchor).isActive=true
        infoButton.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive=true
        infoButton.widthAnchor.constraint(equalToConstant: 50).isActive=true
        infoButton.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/4).isActive=true
        
        // setup constraints for status labels
        tempStatusLabel.rightAnchor.constraint(equalTo: inputsContainerView.rightAnchor, constant: -12).isActive=true
        tempStatusLabel.topAnchor.constraint(equalTo: infoButton.bottomAnchor).isActive=true
        tempStatusLabel.widthAnchor.constraint(equalToConstant: 120).isActive=true
        tempStatusLabel.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/4).isActive=true
        
        beaconStatusLabel.rightAnchor.constraint(equalTo: inputsContainerView.rightAnchor, constant: -12).isActive=true
        beaconStatusLabel.topAnchor.constraint(equalTo: tempStatusLabel.bottomAnchor).isActive=true
        beaconStatusLabel.widthAnchor.constraint(equalToConstant: 120).isActive=true
        beaconStatusLabel.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/4).isActive=true
    
        activeStatusLabel.rightAnchor.constraint(equalTo: inputsContainerView.rightAnchor, constant: -12).isActive=true
        activeStatusLabel.topAnchor.constraint(equalTo: beaconStatusLabel.bottomAnchor).isActive=true
        activeStatusLabel.widthAnchor.constraint(equalToConstant: 120).isActive=true
        activeStatusLabel.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/4).isActive=true
        
        // setup constarints for loading views
        temp_loadingView.translatesAutoresizingMaskIntoConstraints = false
        temp_loadingView.rightAnchor.constraint(equalTo: inputsContainerView.rightAnchor, constant: 35).isActive=true
        temp_loadingView.topAnchor.constraint(equalTo: infoButton.bottomAnchor).isActive=true
        temp_loadingView.widthAnchor.constraint(equalToConstant: 120).isActive=true
        temp_loadingView.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/4).isActive=true
        
        beacon_loadingView.translatesAutoresizingMaskIntoConstraints = false
        beacon_loadingView.rightAnchor.constraint(equalTo: inputsContainerView.rightAnchor, constant: 35).isActive=true
        beacon_loadingView.topAnchor.constraint(equalTo: tempStatusLabel.bottomAnchor).isActive=true
        beacon_loadingView.widthAnchor.constraint(equalToConstant: 120).isActive=true
        beacon_loadingView.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/4).isActive=true
        
        weight_loadingView.translatesAutoresizingMaskIntoConstraints = false
        weight_loadingView.rightAnchor.constraint(equalTo: inputsContainerView.rightAnchor, constant: 35).isActive=true
        weight_loadingView.topAnchor.constraint(equalTo: beaconStatusLabel.bottomAnchor).isActive=true
        weight_loadingView.widthAnchor.constraint(equalToConstant: 120).isActive=true
        weight_loadingView.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/4).isActive=true
        
        // setup constraints for seperator fields
        identifierSeperatorView.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive=true
        identifierSeperatorView.topAnchor.constraint(equalTo: deviceIdentifierLabel.bottomAnchor, constant: -3).isActive=true
        identifierSeperatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive=true
        identifierSeperatorView.heightAnchor.constraint(equalToConstant: 3).isActive=true

        tempSeperatorView.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive=true
        tempSeperatorView.topAnchor.constraint(equalTo: tempTextLabel.bottomAnchor).isActive=true
        tempSeperatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive=true
        tempSeperatorView.heightAnchor.constraint(equalToConstant: 1).isActive=true
        
        weightSeperatorView.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive=true
        weightSeperatorView.topAnchor.constraint(equalTo: beaconTextLabel.bottomAnchor).isActive=true
        weightSeperatorView.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive=true
        weightSeperatorView.heightAnchor.constraint(equalToConstant: 1).isActive=true
    }
    
    // MARK: UI adjustment functions
    func adjustTemperature(_ newTemp: String) {
        tempStatusLabel.text = newTemp
    }
    
    func adjustBeaconStatus(_ beaconStatus: String) {
        beaconStatusLabel.text = beaconStatus
    }
    
    func adjustActiveStatus(_ isWeight: Bool) {
        activeStatusLabel.text = isWeight ? yes : no
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
        if !temp_loadingView.isAnimating && !tempStatusLabel.isHidden {
            temp_loadingView.startAnimating()
            tempStatusLabel.isHidden = true
            let timer = CustomTimer(timeInterval: 20) { [weak self] in
                self?.hideTempSpinner()
            }
            timer.start()
        }
    }
    
    func hideTempSpinner()  {
        if temp_loadingView.isAnimating && tempStatusLabel.isHidden {
            temp_loadingView.stopAnimating()
            tempStatusLabel.isHidden = false
        }
    }
    
    func showBeaconSpinner() {
        if !beacon_loadingView.isAnimating && !beaconStatusLabel.isHidden {
            beacon_loadingView.startAnimating()
            beaconStatusLabel.isHidden = true
            let timer = CustomTimer(timeInterval: 20) { [weak self] in
                self?.hideBeaconSpinner()
            }
            timer.start()
        }
    }
    
    func hideBeaconSpinner() {
        if beacon_loadingView.isAnimating && beaconStatusLabel.isHidden {
            beacon_loadingView.stopAnimating()
            beaconStatusLabel.isHidden = false
        }
    }
    
    func showWeightSpinner() {
        if !weight_loadingView.isAnimating && !activeStatusLabel.isHidden {
            weight_loadingView.startAnimating()
            activeStatusLabel.isHidden = true
            let timer = CustomTimer(timeInterval: 20) { [weak self] in
                self?.hideWeightSpinner()
            }
            timer.start()
        }
    }
    
    func hideWeightSpinner() {
        if weight_loadingView.isAnimating && activeStatusLabel.isHidden {
            weight_loadingView.stopAnimating()
            activeStatusLabel.isHidden = false
        }
    }
    
    // MARK: Info Button Setup
    @objc func showDeviceInfo() {
        let whatsNew = WhatsNew(
            title: "Information about Device",
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
        
        present(whatsNewViewController, animated: true)
    }
}
