//
//  BluetoothExtension.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 10/20/18.
//  Copyright © 2018 Guardian Angel. All rights reserved.
//

import UIKit
import CoreBluetooth

extension DeviceViewController: CBPeripheralDelegate, CBCentralManagerDelegate {
    /// Scan for bluetooth peripherals in the background
    func backgroundScan() {
        guard let isScan = centralManager?.isScanning, !isUartConnected && !isScan else { return }
        print("Now Background Scanning...")
        
        // In order to perform background scanning, we must request a particular service
        let cbUUID1 = CBUUID(string: "00000001-1212-EFDE-1523-785FEABCD123")
        let cbUUID2 = CBUUID(string: kBLEService_UUID)
        let cbUUID3 = CBUUID(string: kBLE_Characteristic_uuid_Rx)
        let cbUUID4 = CBUUID(string: kBLE_Characteristic_uuid_Tx)
        let cbArray = [cbUUID1,cbUUID2,cbUUID3,cbUUID4]
        // Start scanning
        centralManager?.scanForPeripherals(withServices: cbArray, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        
        // Setup timer to stop scanning
        let timer = CustomTimer(timeInterval: 30) {
            self.stopScan()
        }
        timer.start()
    }
    
    /// Scan for bluetooth peripherals in the foreground
    @objc func foregroundScan() {
        guard let isScan = centralManager?.isScanning, !isUartConnected && !isScan else { return }
        print("Now Foreground Scanning...")
        // Start scanning
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        
        // Setup timer to stop scanning
        let timer = CustomTimer(timeInterval: 30) {
            self.stopScan()
        }
        timer.start()
    }
    
    /// Stop scanning for bluetooth devices
    func stopScan() {
        self.centralManager?.stopScan()
    }
    
    /// Restart bluetooth manager
    func restartCentralManager() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        guard let manager = centralManager else { return }
        centralManagerDidUpdateState(manager)
    }
    
    // Discovered peripheral
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard peripheral.identifier == UART_UUID && !isUartConnected else { return }
        selectedPeripheral = peripheral
        //Connect to peripheral
        centralManager?.connect(peripheral, options: nil)
    }
    
    // Connected to peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //Stop Scan- We don't need to scan once we've connected to a peripheral. We got what we came for.
        stopScan()
        if AppDelegate.isDebugging {
            sendConnectedLocalNotification()
        }
        // Modify state
        isUartConnected = true
        // Setup UI
        executeOnMainThread {
            self.setTitleConnected()
        }
        //Discovery callback
        peripheral.delegate = self
        //Only look for services that matches transmit uuid
        peripheral.discoverServices([BLEService_UUID])
    }

    
    /*
     Invoked when you discover the peripheral’s available services.
     This method is invoked when your app calls the discoverServices(_:) method. If the services of the peripheral are successfully discovered, you can access them through the peripheral’s services property. If successful, the error parameter is nil. If unsuccessful, the error parameter returns the cause of the failure.
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services, error == nil else {
            // Show error message
            showAlertMessage(presenter: self, title: "Error", message: "There was a problem connecting to the cushion")
            return
        }
        //We need to discover the all characteristic
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
        print("Discovered Services: \(services)")
    }
    /*
     Invoked when you discover the characteristics of a specified service.
     This method is invoked when your app calls the discoverCharacteristics(_:for:) method. If the characteristics of the specified service are successfully discovered, you can access them through the service's characteristics property. If successful, the error parameter is nil. If unsuccessful, the error parameter returns the cause of the failure.
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics, error == nil else {
            // Show error message
            showAlertMessage(presenter: self, title: "Error", message: "There was a problem connecting to the cushion")
            return
        }
        
        print("Found \(characteristics.count) characteristics!")
        for characteristic in characteristics {
            // We only care about the Rx characteristic
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Rx)  {
                rxCharacteristic = characteristic
                
                //Once found, subscribe to the this particular characteristic...
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                // We can return after calling CBPeripheral.setNotifyValue because CBPeripheralDelegate's
                // didUpdateNotificationStateForCharacteristic method will be called automatically
                peripheral.readValue(for: characteristic)
                print("Rx Characteristic: \(characteristic.uuid)")
            }
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    // Getting Values from UART
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic == rxCharacteristic {
            if let ASCIIstring = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue) {
                let uartValue = ASCIIstring
                //print("Device Location: \(String(describing: device.locationString()))")
                //print("Value Recieved: \((uartValue as String))")
                executeOnMainThread {
                    // Hide spinners
                    self.hideTempSpinner()
                    self.hideWeightSpinner()
                }
                
                let parsedUartValues = uartValue.components(separatedBy: " ")
                var parsedTempString: String = ""
                var parsedWeightString: String = ""
                if uartValue == "" {
                    print("No data")
                    parsedTempString = notConnected
                    parsedWeightString = "No"
                } else {
                    let tempString = parsedUartValues[0]
                    let weightString = parsedUartValues[1]
                    let parseTemp = try! NSRegularExpression(pattern: "T=", options: NSRegularExpression.Options.caseInsensitive)
                    parsedTempString = parseTemp.stringByReplacingMatches(in: tempString, options: [], range: NSRange(0..<tempString.count), withTemplate: "")
                    let parseWeight = try! NSRegularExpression(pattern: "W=", options: NSRegularExpression.Options.caseInsensitive)
                    parsedWeightString = parseWeight.stringByReplacingMatches(in: weightString, options: [], range: NSRange(0..<weightString.count), withTemplate: "")
                }
                let convertedTemp: String = convertTempString(parsedTempString)
                var tempWithDegree: String = ""
                print("temperature: \(convertedTemp)˚F")
                if parsedTempString != "invalid" && AppDelegate.is_temp_enabled {
                    tempWithDegree = AppDelegate.farenheit_celsius ? "\(convertedTemp)˚F" : convertedTemp.farenheitToCelsius()
                } else {
                    tempWithDegree = notConnected
                }

                let temp = Int(convertedTemp)
                let weight = Int(parsedWeightString)
                
                var weightText = ""
                if let weight = weight, weight < 3000 {
                    weightText = "Yes"
                    isBabyInSeat = true
                } else {
                    weightText = "No"
                    isBabyInSeat = false
                }
                // Setup UI
                executeOnMainThread {
                    self.tempStatusLabelField.text = tempWithDegree
                    self.activeStatusLabelField.text = weightText
                }
                // Send temperature notification
                if let temp = temp, temp > maxTemp && isBabyInSeat && AppDelegate.is_temp_enabled {
                    sendTemperatureLocalNotification()
                }
            }
        }
    }
    
    // Disconnected from peripheral
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected")
        // Modify state
        isUartConnected = false
        // Setup UI
        executeOnMainThread {
            self.tempStatusLabelField.text = notConnected
            self.beaconStatusLabelField.text = notConnected
            self.activeStatusLabelField.text = "No"
            self.setTitleDisconnected()
        }
        
        // Reconnect to UART
        backgroundScan()
        
        if AppDelegate.isDebugging {
            sendDisconnectedLocalNotification()
        } else {
            sendLeftRegionLocalNotification()
        }
        
    }
    
    // Bluetooth is disabled
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != CBManagerState.poweredOn {
            executeOnMainThread {
                // Setup UI
                self.hideTempSpinner()
                self.hideBeaconSpinner()
                self.hideWeightSpinner()
                self.setTitleDisconnected()
                // Show error message
                showAlertMessage(presenter: self, title: "Bluetooth is not enabled", message: "Make sure that your Bluetooth is turned on")
            }
        }
    }
    
    // Connection failed
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            // Modify state
            isUartConnected = false
            // Setup UI
            executeOnMainThread {
                self.hideTempSpinner()
                self.hideWeightSpinner()
                self.setTitleDisconnected()
                // Show error message
                showAlertMessage(presenter: self, title: "Error", message: "There was a problem connecting to the cushion")
            }
        }
    }
}

