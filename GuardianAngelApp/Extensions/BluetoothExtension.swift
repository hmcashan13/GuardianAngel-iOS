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
    
    func altScan() {
        centralManager?.scanForPeripherals(withServices: cbarray, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
    }
    @objc func startScan() {
        guard !uart_is_connected else { return }
        print("Now Scanning...")
        // Start scanning
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        
        // Setup timer to stop scanning
        let timer = CustomTimer {
            self.stopScan()
        }
        timer.start()
    }
    func stopScan() {
        self.centralManager?.stopScan()
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            return
        }
        print("Peripheral manager is running")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Device subscribe to characteristic")
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != CBManagerState.poweredOn {
            //If Bluetooth is off, display a UI alert message saying "Bluetooth is not enable" and "Make sure that your bluetooth is turned on"
            print("Bluetooth Disabled- Make sure your Bluetooth is turned on")
            
            let alertVC = UIAlertController(title: "Bluetooth is not enabled", message: "Make sure that your bluetooth is turned on", preferredStyle: UIAlertController.Style.alert)
            let action = UIAlertAction(title: "ok", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
                self.dismiss(animated: true, completion: nil)
            })
            alertVC.addAction(action)
            DispatchQueue.main.async {
                self.present(alertVC, animated: true, completion: nil)
            }
        }
    }
    func restoreCentralManager() {
        //Restores Central Manager delegate if something went wrong
        centralManager?.delegate = self
    }
    //Found peripheral
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //sendStartScanNotification()
        guard peripheral.identifier == UART_UUID && !uart_is_connected else { return }
        print("connected device: ", peripheral)
        //guard let services = peripheral.services else { return }
        //for service in services {
        //    print("services: ", service)
        //}
        sendLocalNotificationConnected()
        selectedPeripheral = peripheral
        //Connect to peripheral
        centralManager?.connect(peripheral, options: nil)
    }
    
    func restartCentralManager() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        guard let manager = centralManager else { return }
        centralManagerDidUpdateState(manager)
    }
    
    //-Connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("*****************************")
        print("Connection complete")
        print("Peripheral info: \(String(describing: blePeripheral))")
        print("state: \(String(describing: blePeripheral?.state.rawValue))")
        //Stop Scan- We don't need to scan once we've connected to a peripheral. We got what we came for.
        centralManager?.stopScan()
        print("Scan Stopped")
        // Set uart connection state
        uart_is_connected = true
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
            uart_is_connected = false
            print("Failed to connect to peripheral")
            return
        }
    }
    
    /*
     Invoked when you discover the peripheral’s available services.
     This method is invoked when your app calls the discoverServices(_:) method. If the services of the peripheral are successfully discovered, you can access them through the peripheral’s services property. If successful, the error parameter is nil. If unsuccessful, the error parameter returns the cause of the failure.
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("*******************************************************")
        
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        //We need to discover the all characteristic
        for service in services {
            
            peripheral.discoverCharacteristics(nil, for: service)
            // bleService = service
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
                characteristicASCIIValue = ASCIIstring
                //print("Device Location: \(String(describing: device.locationString()))")
                print("Value Recieved: \((characteristicASCIIValue as String))")
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: "Notify"), object: nil)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("*******************************************************")
        
        if error != nil {
            print("\(error.debugDescription)")
            return
        }
        if ((characteristic.descriptors) != nil) {
            
            for x in characteristic.descriptors!{
                let descript = x as CBDescriptor?
                print("function name: DidDiscoverDescriptorForChar \(String(describing: descript?.description))")
                print("Rx Value \(String(describing: rxCharacteristic?.value))")
                print("Tx Value \(String(describing: txCharacteristic?.value))")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("*******************************************************")
        
        if (error != nil) {
            print("Error changing notification state:\(String(describing: error?.localizedDescription))")
            
        } else {
            print("Characteristic's value subscribed")
        }
        
        if (characteristic.isNotifying) {
            print ("Subscribed. Notification has begun for: \(characteristic.uuid)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        uart_is_connected = false
        tempStatusLabelField.text = "Not Connected"
        activeStatusLabelField.text = "No"
        print("Disconnected")
        sendLocalNotificationDisconnected()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
        print("Message sent")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
        print("Succeeded!")
    }
    
    func updateIncomingData() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "Notify"), object: nil , queue: nil){
            notification in
            // Hide spinners
            self.hideTempSpinner()
            self.hideWeightSpinner()
            
            let uartString = self.characteristicASCIIValue
            
            let readings = uartString.components(separatedBy: " ")
//            print("uartString: ", uartString)
            var parsedTempString: String = ""
            var parsedWeightString: String = ""
//            if uartString == "" || readings.count <= 3 {
//                print("No data")
//                parsedTempString = "invalid"
//                parsedWeightString = "Not Connnected"
//            } else {
                parsedTempString = "70"//readings[1]
                parsedWeightString = "200"//readings[3]
//            }
            
            if parsedTempString != "invalid" && AppDelegate.is_temp_enabled {
                let tempWithDegree: String = AppDelegate.farenheit_celsius ? "\(parsedTempString)˚F" : parsedTempString.farenheitToCelsius()
                self.tempStatusLabelField.text = tempWithDegree
            } else {
                self.tempStatusLabelField.text = "Not Connected"
            }
            
            let weight: Int? = Int(parsedWeightString)
            let temp: Int? = Int(parsedTempString)
            
            if let weight = weight, weight > 100 {
                self.activeStatusLabelField.text = "Yes"
                self.is_baby_in_seat = true
            } else {
                self.activeStatusLabelField.text = "No"
                self.is_baby_in_seat = false
            }
            if let temp = temp, temp > self.maxTemp && self.is_baby_in_seat && AppDelegate.is_temp_enabled {
                self.sendLocalNotificationTemperature()
                self.beaconStatusLabelField.text = "Alarm"
            }
        }
    }
}

