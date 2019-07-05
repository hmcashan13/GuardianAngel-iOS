//
//  GPSViewController.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 7/3/19.
//  Copyright © 2019 Guardian Angel. All rights reserved.
//

import UIKit
import WhatsNewKit

class GPSViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup UI
        title = "GPS Tracker"
        view.backgroundColor = UIColor(displayP3Red: 0.7, green: 0.4, blue: 1.0, alpha: 1.0)
        
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(showGPSInfo), for: .touchUpInside)
        let infoBarButtonItem = UIBarButtonItem(customView: infoButton)
        navigationItem.leftBarButtonItem = infoBarButtonItem
    }

    @objc func showGPSInfo() {
        let whatsNew = WhatsNew(
            title: "Information about the GPS",
            items: [
                WhatsNew.Item(
                    title: "Temperature Section:",
                    subtitle: "The temperature calculated by the smart cushion",
                    image: UIImage(named: "temp")
                ),
                WhatsNew.Item(
                    title: "Proximity from Cushion Section:",
                    subtitle: "Provides information about the proximity of the user from the smart cushion",
                    image: UIImage(named: "proximity")
                ),
                WhatsNew.Item(
                    title: "Device Active Section:",
                    subtitle: "Determines if weight is detected on cushion. You can only receive notifications if the device is active",
                    image: UIImage(named: "setup")
                ),
                WhatsNew.Item(
                    title: "Questions?",
                    subtitle: "Email us at support@guardianangelcushion.com",
                    image: UIImage(named: "question")
                )
            ]
        )
        
        let myTheme = WhatsNewViewController.Theme { configuration in
            configuration.titleView.titleColor = .white
            configuration.backgroundColor = UIColor(displayP3Red: 0.7, green: 0.4, blue: 1.0, alpha: 1.0)
            configuration.itemsView.titleFont = .boldSystemFont(ofSize: 22)
            configuration.itemsView.titleColor = .white
            configuration.itemsView.subtitleFont = .systemFont(ofSize: 13.2)
            configuration.itemsView.subtitleColor = .white
            configuration.completionButton.title = "Go Back"
            configuration.completionButton.backgroundColor = .white
            configuration.completionButton.titleColor = UIColor(displayP3Red: 0.7, green: 0.4, blue: 1.0, alpha: 1.0)
        }
        
        let configuration = WhatsNewViewController.Configuration(
            theme: myTheme
        )
        
        let whatsNewViewController = WhatsNewViewController(
            whatsNew: whatsNew,
            configuration: configuration
        )
        
        present(whatsNewViewController, animated: true)
    }
}
