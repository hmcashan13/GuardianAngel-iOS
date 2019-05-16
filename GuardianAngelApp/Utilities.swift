//
//  Utils.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 5/4/19.
//  Copyright © 2019 Guardian Angel. All rights reserved.
//

import UIKit

class Utilities {
    static func showAlertMessage(presenter: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        presenter.present(alert, animated: true, completion: nil)
    }
    
    static func executeOnMainThread(completion: @escaping () -> Void) {
        if Thread.isMainThread {
            completion()
        } else {
            DispatchQueue.main.async {
                completion()
            }
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
