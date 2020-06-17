//
//  LocationExtension.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 11/11/18.
//  Copyright © 2018 Guardian Angel. All rights reserved.
//

import CoreLocation

// Location extension responsible for handling Beacon connection
extension DeviceViewController: CLLocationManagerDelegate {
    // MARK: Beacon Helper Methods
    /// Stop ranging beacon
    @objc func stopRangingBeacon() {
        locationManager?.stopRangingBeacons(in: beaconRegion)
    }
    /// Start ranging beacon
    @objc func startBeacon() {
        if !isBeaconConnected {
            locationManager?.startMonitoring(for: beaconRegion)
        }
    }
    /// Stop ranging and monitoring beacon
    func stopRangingAndMonitoringBeacon() {
        locationManager?.stopMonitoring(for: beaconRegion)
        locationManager?.stopRangingBeacons(in: beaconRegion)
    }
    
    // MARK: Location Manager Delegate Methods
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        if CLLocationManager.isRangingAvailable() {
            guard let region = region as? CLBeaconRegion else {
                // TODO: handle error
                print("Beacon Region is not valid")
                return
            }
            isBeaconConnected = true
            // Start ranging beacon
            manager.startRangingBeacons(in: region)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if isDebugging {
            print("Entered region")
            sendNotification(description: "Entered Region")
        }
        // Modify state
        isBeaconConnected = true
        // Setup UI
//        showBeaconSpinner()
        // Connect to UART
        if connectionState == .notConnected {
            backgroundScan()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // Modify state
        isBeaconConnected = false
        // Setup UI
        executeOnMainThread { [weak self] in
            self?.adjustBeaconStatus(notConnected)
        }
        // No matter what we want to stop scanning
        stopScan()
        
        if isDebugging {
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
            
            // Setup UI
            if connectionState == .connected {
                adjustBeaconStatus(proximity)
            }
        }
    }
}
