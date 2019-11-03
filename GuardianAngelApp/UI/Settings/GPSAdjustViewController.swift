//
//  GPSAdjustViewController.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 7/6/19.
//  Copyright © 2019 Guardian Angel. All rights reserved.
//

import UIKit

protocol GPSSettingsDelegate: AnyObject {
    func adjustRegionRadius(_ newRadius: Int)
    func disconnectGPS()
}
// TODO: setup
class GPSAdjustViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Adjust GPS Tracker"
        // Do any additional setup after loading the view.
        self.view.backgroundColor = standardColor
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
