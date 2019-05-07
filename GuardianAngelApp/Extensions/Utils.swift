//
//  Utils.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 5/4/19.
//  Copyright © 2019 Guardian Angel. All rights reserved.
//

import UIKit

class Utils {
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
