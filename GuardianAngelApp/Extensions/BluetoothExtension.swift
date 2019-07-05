//
//  BluetoothExtension.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 10/20/18.
//  Copyright © 2018 Guardian Angel. All rights reserved.
//

import UIKit
import CoreBluetooth

extension DeviceViewController: CBPeripheralDelegate, CBCentralManagerDelegate, BluetoothSettingsDelegate {

    
    /// Scan for bluetooth peripherals in the background
    func backgroundScan() {
        guard let isScan = centralManager?.isScanning, connectionState == .notConnected && !isScan else { return }
        print("Now Background Scanning...")
        
        // In order to perform background scanning, we must request a particular service
        let cbUUID1: CBUUID = CBUUID(string: "00000001-1212-EFDE-1523-785FEABCD123")
        let cbUUID2: CBUUID = CBUUID(string: kBLEService_UUID)
        let cbUUID3: CBUUID = CBUUID(string: kBLE_Characteristic_uuid_Rx)
        let cbUUID4: CBUUID = CBUUID(string: kBLE_Characteristic_uuid_Tx)
        let cbArray: [CBUUID] = [cbUUID1,cbUUID2,cbUUID3,cbUUID4]
        // Start scanning
        centralManager?.scanForPeripherals(withServices: cbArray, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        
        // Setup timer to stop scanning
        let timer: CustomTimer = CustomTimer(timeInterval: 30) {
            self.stopScan()
        }
        timer.start()
    }
    
    /// Scan for bluetooth peripherals in the foreground
    @objc func foregroundScan() {
        guard let isScan = centralManager?.isScanning, connectionState == .notConnected && !isScan else { return }
        print("Now Foreground Scanning...")
        // Start scanning
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        
        // Setup timer to stop scanning
        let timer: CustomTimer = CustomTimer(timeInterval: 30) {
            self.stopScan()
        }
        timer.start()
    }
    
    // Disconnect from UART
    func disconnect() {
        guard let peripheral = selectedPeripheral else { return }
        centralManager?.cancelPeripheralConnection(peripheral)
        // Set State
        connectionState = .notConnected
        isBeaconConnected = false
        // Setup UI
        executeOnMainThread { [weak self] in
            self?.tempStatusLabelField.text = notConnected
            self?.beaconStatusLabelField.text = notConnected
            self?.activeStatusLabelField.text = no
        }
    }
    
    /// Stop scanning for bluetooth devices
    func stopScan() {
        centralManager?.stopScan()
    }
    
    /// Restart bluetooth manager
    func restartCentralManager() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        guard let manager = centralManager else { return }
        centralManagerDidUpdateState(manager)
    }
    
    // Discovered peripheral
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard peripheral.identifier == UART_UUID && connectionState == .notConnected else { return }
        selectedPeripheral = peripheral
        //Connect to peripheral
        centralManager?.connect(peripheral, options: nil)
    }
    
    // Connected to peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //Stop Scan- We don't need to scan once we've connected to a peripheral. We got what we came for.
        stopScan()
        if AppDelegate.isDebugging {
            print("Connected")
            sendNotification(description: "Connected")
        }
        // Modify state
        connectionState = .connected
        // Setup UI
        executeOnMainThread { [weak self] in
            self?.setTitleConnected()
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
            showAlertMessage(presenter: self, title: "Error", message: "There was a problem connecting to the cushion", handler: nil)
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
            showAlertMessage(presenter: self, title: "Error", message: "There was a problem connecting to the cushion", handler: nil)
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
                print("Tx Characteristic: \(characteristic.uuid)")
            }
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    // Getting Values from UART
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let ASCIIstring = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue), characteristic == rxCharacteristic {
            let parsedData: (String,String) = parseData(ASCIIstring)
            // Setup UI
            executeOnMainThread { [weak self] in
                self?.hideTempSpinner()
                self?.hideWeightSpinner()
                self?.tempStatusLabelField.text = parsedData.0
                self?.activeStatusLabelField.text = parsedData.1
            }
        }
    }
    
    private func parseData(_ data: NSString) -> (String, String) {
        //print("Device Location: \(String(describing: device.locationString()))")
        //print("Value Recieved: \((uartValue as String))")
        let parsedUartValues: [String] = data.components(separatedBy: " ")
        var parsedTempString: String = ""
        var parsedWeightString: String = ""
        if data == "" {
            print("No data")
            parsedTempString = notConnected
            parsedWeightString = no
        } else {
            let tempString: String = parsedUartValues[0]
            let weightString: String = parsedUartValues[1]
            let parseTemp: NSRegularExpression = try! NSRegularExpression(pattern: "T=", options: NSRegularExpression.Options.caseInsensitive)
            parsedTempString = parseTemp.stringByReplacingMatches(in: tempString, options: [], range: NSRange(0..<tempString.count), withTemplate: "")
            let parseWeight: NSRegularExpression = try! NSRegularExpression(pattern: "W=", options: NSRegularExpression.Options.caseInsensitive)
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
        
        let temp: Int? = Int(convertedTemp)
        let weight: Int? = Int(parsedWeightString)
        
        var weightText: String = ""
        if let weight = weight, weight < 3000 {
            weightText = yes
            isWeightDetected = true
        } else {
            weightText = no
            isWeightDetected = false
        }
        // Send temperature notification only if weight is detected
        if let temp = temp, temp > maxTemp && isWeightDetected && AppDelegate.is_temp_enabled {
            sendTemperatureNotification()
        }
        return (tempWithDegree,weightText)
    }
    
    // Disconnected from peripheral
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // Modify state
        connectionState = .notConnected
        // Setup UI
        executeOnMainThread { [weak self] in
            guard let self = self else { return }
            self.tempStatusLabelField.text = notConnected
            self.beaconStatusLabelField.text = notConnected
            self.activeStatusLabelField.text = no
            self.setTitleDisconnected()
        }
        
        if isBeaconConnected {
            // Reconnect to UART only if we are in the region
            backgroundScan()
        }
        
        if AppDelegate.isDebugging {
             print("Disconnected")
            sendNotification(description: "Disconnected")
        } else if isWeightDetected {
            // Only send notification if weight is detected
            sendTooFarNotification()
        }
        
    }
    
    // Bluetooth is disabled
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != CBManagerState.poweredOn {
            // Setup UI
            executeOnMainThread { [weak self] in
                guard let self = self else { return }
                self.hideTempSpinner()
                self.hideBeaconSpinner()
                self.hideWeightSpinner()
                self.setTitleDisconnected()
                // Show error message
                showAlertMessage(presenter: self, title: "Bluetooth is not enabled", message: "Make sure that your Bluetooth is turned on", handler: nil)
            }
        }
    }
    
    // Connection failed
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            // Modify state
            connectionState = .notConnected
            // Setup UI
            executeOnMainThread { [weak self] in
                guard let self = self else { return }
                self.hideTempSpinner()
                self.hideWeightSpinner()
                self.setTitleDisconnected()
                // Show error message
                showAlertMessage(presenter: self, title: "Error", message: "There was a problem connecting to the cushion", handler: { [weak self] _ in
                    self?.backgroundScan()
                })
            }
        }
    }
}

