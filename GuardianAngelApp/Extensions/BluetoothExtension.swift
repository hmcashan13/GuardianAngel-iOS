//
//  BluetoothExtension.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 10/20/18.
//  Copyright © 2018 Guardian Angel. All rights reserved.
//

import UIKit
import CoreBluetooth

public let babyInSeatNotification = Notification.Name("tempSensorTurnedOff")

extension DeviceViewController: CBPeripheralDelegate, CBCentralManagerDelegate {
    /// Scan for bluetooth peripherals in the background
    func backgroundScan() {
        guard !uart_is_connected else { return }
        print("Now Background Scanning...")
        
        // In order to perform background scanning, we must request a particular service
        let cbUUID1 = CBUUID(string: "00000001-1212-EFDE-1523-785FEABCD123")
        let cbArray = [cbUUID1]
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
        guard !uart_is_connected else { return }
        print("Now Foreground Scanning...")
        // Start scanning
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        
        // Setup timer to stop scanning
        let timer = CustomTimer(timeInterval: 30) {
            self.stopScan()
        }
        timer.start()
    }
    func stopScan() {
        self.centralManager?.stopScan()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != CBManagerState.poweredOn {
            // Bluetooth is disabled
            executeOnMainThread {
                // Setup UI
                self.hideTempSpinner()
                self.hideBeaconSpinner()
                self.hideWeightSpinner()
                self.navigationItem.title = "Not Connected"
                // Show error message
                showAlertMessage(presenter: self, title: "Bluetooth is not enabled", message: "Make sure that your Bluetooth is turned on")
            }
        }
    }
    
    // Discovered peripheral
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard peripheral.identifier == UART_UUID && !uart_is_connected else { return }
        selectedPeripheral = peripheral
        //Connect to peripheral
        centralManager?.connect(peripheral, options: nil)
    }
    
    func restartCentralManager() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        guard let manager = centralManager else { return }
        centralManagerDidUpdateState(manager)
    }
    
    // Connected to peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //Stop Scan- We don't need to scan once we've connected to a peripheral. We got what we came for.
        centralManager?.stopScan()
        if AppDelegate.isDebugging {
            sendLocalNotificationConnected()
        }
        // Modify state
        uart_is_connected = true
        // Setup UI
        executeOnMainThread {
            self.hideTempSpinner()
            self.hideWeightSpinner()
            self.navigationItem.title = "Connected"
        }
        //Discovery callback
        peripheral.delegate = self
        //Only look for services that matches transmit uuid
        peripheral.discoverServices([BLEService_UUID])
    }
    /*
     Invoked when the central manager fails to create a connection with a peripheral.
     */
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            // Modify state
            uart_is_connected = false
            // Setup UI
            executeOnMainThread {
                self.hideTempSpinner()
                self.hideWeightSpinner()
                // Show error message
                showAlertMessage(presenter: self, title: "Error", message: "There was a problem connecting to the cushion")
            }
        }
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
        
        print("*******************************************************")
        
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        print("Found \(characteristics.count) characteristics!")
        
        for characteristic in characteristics {
            //looks for the right characteristic
            
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Rx)  {
                rxCharacteristic = characteristic
                
                //Once found, subscribe to the this particular characteristic...
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                // We can return after calling CBPeripheral.setNotifyValue because CBPeripheralDelegate's
                // didUpdateNotificationStateForCharacteristic method will be called automatically
                peripheral.readValue(for: characteristic)
                print("Rx Characteristic: \(characteristic.uuid)")
            }
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Tx){
                txCharacteristic = characteristic
                print("Tx Characteristic: \(characteristic.uuid)")
            }
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    // Getting Values From Characteristic
    
    /*After you've found a characteristic of a service that you are interested in, you can read the characteristic's value by calling the peripheral "readValueForCharacteristic" method within the "didDiscoverCharacteristicsFor service" delegate.
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic == rxCharacteristic {
            if let ASCIIstring = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue) {
                let uartValues = ASCIIstring
                //print("Device Location: \(String(describing: device.locationString()))")
                //print("Value Recieved: \((uartValues as String))")
                executeOnMainThread {
                    // Hide spinners
                    self.hideTempSpinner()
                    self.hideWeightSpinner()
                }
                
                let parsedUartValues = uartValues.components(separatedBy: " ")
                var parsedTempString: String = ""
                var parsedWeightString: String = ""
                if uartValues == "" {
                    print("No data")
                    parsedTempString = "invalid"
                    parsedWeightString = "Not Connnected"
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
                    tempWithDegree = "Not Connected"
                }

                let temp = Int(convertedTemp)
                let weight = Int(parsedWeightString)
                
                var weightText = ""
                if let weight = weight, weight < 3000 {
                    weightText = "Yes"
                    is_baby_in_seat = true
                } else {
                    weightText = "No"
                    is_baby_in_seat = false
                }
                // Setup UI
                executeOnMainThread {
                    self.tempStatusLabelField.text = tempWithDegree
                    self.activeStatusLabelField.text = weightText
                }
                // Send temperature notification
                if let temp = temp, temp > maxTemp && is_baby_in_seat && AppDelegate.is_temp_enabled {
                    sendLocalNotificationTemperature()
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected")
        // Modify state
        uart_is_connected = false
        // Setup UI
        executeOnMainThread {
            self.tempStatusLabelField.text = "Not Connected"
            self.activeStatusLabelField.text = "No"
            self.navigationItem.title = "Disconnected"
        }
        
        // Reconnect to UART
        backgroundScan()
        
        sendLocalNotificationDisconnected()
    }
}

