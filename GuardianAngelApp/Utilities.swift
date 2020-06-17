//
//  Utils.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 5/4/19.
//  Copyright © 2019 Guardian Angel. All rights reserved.
//

import UIKit
import CoreBluetooth

// String constants
let connected: String = "Connected"
let notConnected: String = "Not Connected"
let yes: String = "Yes"
let no: String = "No"

// Timer constants
let spinnerInterval: TimeInterval = 10.0
let scannerInterval: TimeInterval = 10.0

// Custom Colors
let standardColor: UIColor = UIColor(red: 150/255, green: 135/255, blue: 200/255, alpha: 1)

/// Present a message to the user (automatically done on the main thread)
func showAlertMessageWithRetry(presenter: UIViewController, title: String, message: String, cancelHandler: ((UIAlertAction) -> Void)?, retryHandler: ((UIAlertAction) -> Void)?) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: cancelHandler))
    alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: retryHandler))
    executeOnMainThread { [weak presenter] in
        presenter?.present(alert, animated: true, completion: nil)
    }
}

/// Present a message to the user (automatically done on the main thread)
func showAlertMessage(presenter: UIViewController, title: String, message: String, handler: ((UIAlertAction) -> Void)?, completion: (() -> Void)?) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: handler))

    executeOnMainThread { [weak presenter] in
        presenter?.present(alert, animated: true, completion: completion)
    }
}

func showAlertMessage(presenter: UIViewController, title: String, message: String, handler: (() -> Void)?) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (alert: UIAlertAction!) in
        if let handler = handler {
            handler()
        }
    }))

    executeOnMainThread { [weak presenter] in
        presenter?.present(alert, animated: true, completion: nil)
    }
}


func convertTempString(_ temperature: String) -> String {
    guard let celsiusTemp: Double = Double(temperature) else { return "" }
    let convertedTemp: Int = Int(celsiusTemp * 9/5) + 32
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
    var timer: Timer?
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
        if let timer: Timer = timer {
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

extension UIImage {
    func maskWithColor(color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        let rect = CGRect(origin: CGPoint.zero, size: size)

        color.setFill()
        self.draw(in: rect)

        context.setBlendMode(.sourceIn)
        context.fill(rect)

        let resultImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resultImage
    }

}
