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
        if !beacon_is_connected {
            locationManager?.startMonitoring(for: beaconRegion)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        if CLLocationManager.isRangingAvailable() {
            guard let region = region as? CLBeaconRegion else {
                print("Beacon Region is not valid")
                return
            }
            beacon_is_connected = true
            // Start ranging beacon
            manager.startRangingBeacons(in: region)
        } else {
            print("Monitoring is NOT available")
        }
        // Start uart
        altScan()
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        beacon_is_connected = true
        showBeaconSpinner()
        print("Entered region")
        if !uart_is_connected {
            altScan()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Adios")
        beacon_is_connected = false
        beaconStatusLabelField.text = "Not Connected"
        if is_baby_in_seat && !uart_is_connected {
            sendLocalNotificationLeftRegion()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if let beacon = beacons.first {
            beacon_is_connected = true
            let distance = beacon.accuracy
            switch distance {
            case _ where distance < 0:
                print("Not Connected")
            case 0...10:
                hideBeaconSpinner()
                proximity = "Very Close"
            case 10...20:
                hideBeaconSpinner()
                proximity = "Near"
            case _ where distance > 20:
                hideBeaconSpinner()
                proximity = "Far"
            default:
                print("Unknown")
            }
            beaconStatusLabelField.text = proximity
            print("beacon distance: \(distance)m")
        }
    }
}
