//
//  BluetoothExtension.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 10/20/18.
//  Copyright © 2018 Guardian Angel. All rights reserved.
//

import UIKit
import CoreBluetooth

let ble_Service_UUID: String = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
let ble_Characteristic_TX: String = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
let ble_Characteristic_RX: String = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
let uart_UUID: UUID = UUID(uuidString: "8519BF04-6C36-4B4A-4182-A2764CE2E05A")!
// Bluetooth Extension that handles UART connection
extension DeviceViewController: CBPeripheralDelegate, CBCentralManagerDelegate {
    // MARK: Bluetooth Helper Methods
    /// Scan for bluetooth peripherals in the background
    func backgroundScan() {
        guard let centralManager = centralManager, centralManager.state == .poweredOn, connectionState == .notConnected, !centralManager.isScanning else { return }
        if isDebugging {
            print("Now Background Scanning...")
        }
        
        // In order to perform background scanning, we must request a particular service
        let cbUUID1: CBUUID = CBUUID(string: "00000001-1212-EFDE-1523-785FEABCD123")
        let cbUUID2: CBUUID = CBUUID(string: ble_Service_UUID)
        let cbUUID3: CBUUID = CBUUID(string: ble_Characteristic_RX)
        let cbUUID4: CBUUID = CBUUID(string: ble_Characteristic_TX)
        let cbArray: [CBUUID] = [cbUUID1,cbUUID2,cbUUID3,cbUUID4]
        // Start scanning
        centralManager.scanForPeripherals(withServices: cbArray, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        
        // Setup timer to stop scanning
        let timer: CustomTimer = CustomTimer(timeInterval: 30) {
            self.stopScan()
        }
        timer.start()
    }
    
    /// Scan for bluetooth peripherals in the foreground
    @objc func foregroundScan() {
        guard let centralManager = centralManager, centralManager.state == .poweredOn, connectionState == .notConnected, !centralManager.isScanning else { return }
        if isDebugging {
            print("Now Foreground Scanning...")
        }
        // Start scanning
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        
        // Setup timer to stop scanning
        let timer: CustomTimer = CustomTimer(timeInterval: scannerInterval) {
            self.stopScan()
        }
        timer.start()
    }
    
    /// Disconnect from UART
    func disconnectDevice() {
        guard let peripherals = selectedPeripherals else { return }
        peripherals.forEach { centralManager?.cancelPeripheralConnection($0 ) }
        // Set State
        connectionState = .notConnected
        isBeaconConnected = false
        // Setup UI
        executeOnMainThread { [weak self] in
            self?.adjustTemperature(notConnected)
            self?.adjustBeaconStatus(notConnected)
            self?.adjustActiveStatus(false)
            self?.setConnectionStatus(.notConnected)
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
    
    // MARK: Central Manager Delegate Methods
    /// Discovered peripheral
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard peripheral.identifier == uart_UUID && connectionState == .notConnected && peripheral.state == .disconnected else { return }
        selectedPeripherals?.append(peripheral)
        if isDebugging {
            print("peripheral: ",peripheral)
        }
        //Connect to peripherals
        centralManager?.connect(peripheral, options: nil)
    }
    
    /// Connected to peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //Stop Scan- We don't need to scan once we've connected to a peripheral. We got what we came for.
        stopScan()
        hideTitleSpinner()
        if isDebugging {
            print("Connected")
            sendNotification(description: "Connected")
        }
        // Modify state
        connectionState = .connected
        // Discovery callback
        peripheral.delegate = self
        // Only look for services that matches transmit uuid
        let BLEService_UUID: CBUUID = CBUUID(string: ble_Service_UUID)
        peripheral.discoverServices([BLEService_UUID])
    }

    /// Disconnected from peripheral
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
          // Modify state
          connectionState = .notConnected
          // Setup UI
          executeOnMainThread { [weak self] in
              guard let self = self else { return }
              self.adjustTemperature(notConnected)
              self.adjustBeaconStatus(notConnected)
              self.adjustActiveStatus(false)
              self.setConnectionStatus(.notConnected)
          }
          
          if isBeaconConnected {
              // Reconnect to UART only if we are in the region
              backgroundScan()
          }
          
          if isDebugging {
               print("Disconnected")
              sendNotification(description: "Disconnected")
          } else if isWeightDetected {
              // Only send notification if weight is detected
              sendTooFarNotification()
          }
          
      }
      
    /// Bluetooth is disabled
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // TODO: check for all states
        if central.state != CBManagerState.poweredOn {
          // Setup UI
          executeOnMainThread { [weak self] in
              guard let self = self else { return }
              self.setConnectionStatus(.notConnected)
              self.hideTempSpinner()
              self.hideBeaconSpinner()
              self.hideWeightSpinner()
              self.hideTitleSpinner()
              // Show error message only if logged in
              showAlertMessage(presenter: self, title: "Bluetooth is not enabled", message: "Make sure that your Bluetooth is turned on", handler: nil, completion: nil)
          }
        }
    }

    /// Connection failed
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
          if error != nil {
              // Modify state
              connectionState = .notConnected
              // Setup UI
              executeOnMainThread { [weak self] in
                  guard let self = self else { return }
                  self.setConnectionStatus(.notConnected)
                  self.hideTempSpinner()
                  self.hideWeightSpinner()
                  self.hideTitleSpinner()
                  // Show error message
                // TODO: formatting and retry and cancel option for alert message
                  showAlertMessage(presenter: self, title: "Error", message: "There was a problem connecting to the cushion", handler: {
                      self.backgroundScan()
                  })
              }
          }
      }
    
    // MARK: Peripheral Delegate Methods
    /*
     Invoked when you discover the peripheral’s available services.
     This method is invoked when your app calls the discoverServices(_:) method. If the services of the peripheral are successfully discovered, you can access them through the peripheral’s services property. If successful, the error parameter is nil. If unsuccessful, the error parameter returns the cause of the failure.
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services, error == nil else {
            // Show error message
            // TODO: retry and cancel option
            showAlertMessage(presenter: self, title: "Error", message: "There was a problem connecting to the cushion", handler: nil)
            return
        }
        // We need to discover all characteristic
        services.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
        if isDebugging {
            print("Discovered Services: \(services)")
        }
    }
    /*
     Invoked when you discover the characteristics of a specified service.
     This method is invoked when your app calls the discoverCharacteristics(_:for:) method. If the characteristics of the specified service are successfully discovered, you can access them through the service's characteristics property. If successful, the error parameter is nil. If unsuccessful, the error parameter returns the cause of the failure.
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let BLE_Characteristic_uuid_Rx: CBUUID = CBUUID(string: ble_Characteristic_RX)
        guard let characteristics = service.characteristics, error == nil else { return }
        
        if isDebugging {
            print("Found \(characteristics.count) characteristics!")
        }
        
        for characteristic in characteristics {
            // We only care about the Rx characteristic
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Rx)  {
                rxCharacteristic = characteristic
                
                //Once found, subscribe to the this particular characteristic...
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                // We can return after calling CBPeripheral.setNotifyValue because CBPeripheralDelegate's
                // didUpdateNotificationStateForCharacteristic method will be called automatically
                peripheral.readValue(for: characteristic)
                if isDebugging {
                    print("Tx Characteristic: \(characteristic.uuid)")
                }
            }
            peripheral.discoverDescriptors(for: characteristic)
        }
        // Setup UI
        let timer = CustomTimer(timeInterval: 3) {
            executeOnMainThread { [weak self] in
                self?.setConnectionStatus(.connected)
                self?.hideTempSpinner()
                self?.hideBeaconSpinner()
                self?.hideWeightSpinner()
                self?.hideTitleSpinner()
            }
        }
        timer.start()
    }
    /// Getting Data from UART
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value, let ASCIIstring = NSString(data: value, encoding: String.Encoding.utf8.rawValue), characteristic == rxCharacteristic {
            let parsedData: (String,Bool) = parseData(ASCIIstring)
            // Setup UI 
            executeOnMainThread { [weak self] in
                self?.adjustTemperature(parsedData.0)
                self?.adjustActiveStatus(parsedData.1)
            }
        }
    }
    /// Parsing Data from UART
    private func parseData(_ data: NSString) -> (String, Bool) {
        //print("Device Location: \(String(describing: device.locationString()))")
        //print("Value Recieved: \((uartValue as String))")
        let uartValues: [String] = data.components(separatedBy: " ")
        var tempString: String = ""
        var weightString: String = ""
        var temp: Int?
        var weight: Int?
        if data == "" || !AppDelegate.is_temp_enabled {
            tempString = notConnected
        } else {
            var rawTempString: String = uartValues[0]
            let rawWeightString: String = uartValues[1]
            let removeT: NSRegularExpression = try! NSRegularExpression(pattern: "T=", options: NSRegularExpression.Options.caseInsensitive)
            rawTempString = removeT.stringByReplacingMatches(in: rawTempString, options: [], range: NSRange(0..<rawTempString.count), withTemplate: "")
            let removeComma: NSRegularExpression = try! NSRegularExpression(pattern: ",", options: NSRegularExpression.Options.caseInsensitive)
            tempString = removeComma.stringByReplacingMatches(in: rawTempString, options: [], range: NSRange(0..<rawTempString.count), withTemplate: ".")
            let removeW: NSRegularExpression = try! NSRegularExpression(pattern: "W=", options: NSRegularExpression.Options.caseInsensitive)
            weightString = removeW.stringByReplacingMatches(in: rawWeightString, options: [], range: NSRange(0..<rawWeightString.count), withTemplate: "")
            temp = Int(tempString)
            weight = Int(weightString)
            if let convertedTemp = tempString.celsiusToFarenheit() {
                tempString = AppDelegate.fahrenheit_celsius ? "\(convertedTemp)˚F" : "\(tempString)˚C"
            } else {
                tempString = notConnected
            }
            
        }
        if isDebugging {
            print("temperature: \(tempString)")
        }
        
        
        if let weight = weight, weight < 3000 {
            isWeightDetected = true
        } else {
            isWeightDetected = false
        }
        // Send temperature notification only if weight is detected
        if let temp = temp, temp > AppDelegate.max_temp && isWeightDetected && AppDelegate.is_temp_enabled {
            sendTemperatureNotification()
        }
        return (tempString,isWeightDetected)
    }
    
  
}

