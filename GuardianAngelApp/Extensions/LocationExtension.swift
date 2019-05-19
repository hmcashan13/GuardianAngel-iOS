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
        print("Stop beacon")
        locationManager?.stopRangingBeacons(in: beaconRegion)
    }
    
    @objc func startBeaconAndUart() {
        print("Start beacon")
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
        print("Entered region")
        // Modify state
        isBeaconConnected = true
        // Setup UI
        showBeaconSpinner()
        // Start UART
        backgroundScan()
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Adios")
        // Modify state
        isBeaconConnected = false
        // Setup UI
        beaconStatusLabelField.text = "Not Connected"
        // No matter what we want to stop scanning
        stopScan()
        // TODO: fix it to where we only send notification if baby is in the seat
//        if is_baby_in_seat && !uart_is_connected {
        if !isUartConnected {
            sendLocalNotificationLeftRegion()
        }
//        }

    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if let beacon = beacons.first {
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
            beaconStatusLabelField.text = proximity
        }
    }
}
