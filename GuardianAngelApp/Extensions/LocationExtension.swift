//
//  LocationExtension.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 11/11/18.
//  Copyright © 2018 Guardian Angel. All rights reserved.
//

import CoreLocation

extension DeviceViewController: CLLocationManagerDelegate {
    @objc func stopBeacon() {
        locationManager?.stopRangingBeacons(in: beaconRegion)
    }
    
    @objc func startBeaconAndUart() {
        if !isBeaconConnected {
            locationManager?.startMonitoring(for: beaconRegion)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        if CLLocationManager.isRangingAvailable() {
            guard let region = region as? CLBeaconRegion else {
                print("Beacon Region is not valid")
                return
            }
            // Start ranging beacon
            manager.startRangingBeacons(in: region)
        }
        // Start UART
        backgroundScan()
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if AppDelegate.isDebugging {
            print("Entered region")
            sendNotification(description: "Entered Region")
        }
        // Modify state
        isBeaconConnected = true
        // Setup UI
        showBeaconSpinner()
        // Connect to UART
        if connectionState == .notConnected {
            backgroundScan()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Adios")
        // Modify state
        isBeaconConnected = false
        // Setup UI
        executeOnMainThread { [weak self] in
            self?.beaconStatusLabelField.text = notConnected
        }
        // No matter what we want to stop scanning
        stopScan()
        
        if AppDelegate.isDebugging {
            print("Left Region")
            sendNotification(description: "Left Region")
        } 
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if let beacon = beacons.first {
            // Only displaying proximity info if we are connected to UART
            guard connectionState == .connected else {
                // attempting to reconnect because we should be close enough to device
                backgroundScan()
                return
            }
            let distance = beacon.accuracy
            switch distance {
            case _ where distance < 0:
                print("")
            case 0...10:
                proximity = "Very Close"
            case 10...20:
                proximity = "Near"
            case _ where distance > 20:
                proximity = "Far"
            default:
                print("")
            }
            print("beacon distance: \(distance)m")
            
            // Modify state
            isBeaconConnected = true
            // Setup UI
            hideBeaconSpinner()
            if connectionState == .connected {
                beaconStatusLabelField.text = proximity
            }
        }
    }
}
