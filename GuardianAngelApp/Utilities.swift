//
//  Utils.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 5/4/19.
//  Copyright © 2019 Guardian Angel. All rights reserved.
//

import UIKit
import CoreBluetooth

let kBLEService_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
let kBLE_Characteristic_uuid_Tx = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
let kBLE_Characteristic_uuid_Rx = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
let MaxCharacters = 20

let BLEService_UUID = CBUUID(string: kBLEService_UUID)
let BLE_Characteristic_uuid_Tx = CBUUID(string: kBLE_Characteristic_uuid_Tx)//(Property = Write without response)
let BLE_Characteristic_uuid_Rx = CBUUID(string: kBLE_Characteristic_uuid_Rx)// (Property = Read/Notify)

let notConnected = "Not Connected"
/// Present a message to the user (automatically done on the main thread)
func showAlertMessage(presenter: UIViewController, title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
    executeOnMainThread {
        presenter.present(alert, animated: true, completion: nil)
    }
}

func convertTempString(_ temperature: String) -> String {
    guard let temp = Double(temperature) else { return "" }
    let convertedTemp = Int(temp / 21.5)
    return String(convertedTemp)
}

/// Ensure the execution of the code is done on the main thread, for UI purposes
func executeOnMainThread(completion: @escaping () -> Void) {
    if Thread.isMainThread {
        completion()
    } else {
        DispatchQueue.main.async {
            completion()
        }
    }
}

class CustomTimer {
    typealias Update = ()->Void
    var timer:Timer?
    var count: Int = 0
    var update: Update?
    let timeInterval: TimeInterval
    
    init(timeInterval: TimeInterval, update:@escaping Update){
        self.timeInterval = timeInterval
        self.update = update
    }
    func start(){
        timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(timerUpdate), userInfo: nil, repeats: false)
    }
    func stop(){
        if let timer = timer {
            timer.invalidate()
        }
    }
    /**
     * This method must be in the public or scope
     */
    @objc func timerUpdate() {
        count += 1;
        if let update = update {
            update()
        }
    }
}
