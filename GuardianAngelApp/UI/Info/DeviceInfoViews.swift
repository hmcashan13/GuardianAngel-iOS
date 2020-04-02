//
//  DeviceInfoViews.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 4/2/20.
//  Copyright © 2020 Guardian Angel. All rights reserved.
//

import UIKit
import WhatsNewKit

extension DeviceViewController {
     // MARK: Info Pages
        @objc func goToGeneralInfoView() {
            var whatsNew: WhatsNew?
            if #available(iOS 13.0, *) {
                whatsNew = WhatsNew(
                    title: "Information about Connecting to Device",
                    items: [
                        WhatsNew.Item(
                            title: "Ensure Bluetooth is Enabled:",
                            subtitle: "Go to Settings > Bluetooth > Turn On",
                            image: UIImage(named: "bluetooth")
                        ),
                        WhatsNew.Item(
                            title: "Ensure Smart Cushion is On:",
                            subtitle: "There is a button on the cushion that should be lit when turned on",
                            image: UIImage(systemName: "power")
                        ),
                        WhatsNew.Item(
                            title: "Proximity from Smart Cushion:",
                            subtitle: "Ensure you are within 10 feet of the cushion to connect",
                            image: UIImage(named: "proximity")
                        ),
                        WhatsNew.Item(
                            title: "Questions?",
                            subtitle: "Email us at support@guardianangelcushion.com",
                            image: UIImage(named: "question")
                        )
                    ]
                )
            } else {
                whatsNew = WhatsNew(
                    title: "Information about Connecting to Device",
                    items: [
                        WhatsNew.Item(
                            title: "Ensure Bluetooth is Enabled:",
                            subtitle: "Go to Settings > Bluetooth > Turn On",
                            image: UIImage(named: "bluetooth")
                        ),
                        WhatsNew.Item(
                            title: "Ensure Smart Cushion is On:",
                            subtitle: "There is a button on the cushion that should be lit when turned on",
                            image: UIImage(named: "setup")
                        ),
                        WhatsNew.Item(
                            title: "Proximity from Smart Cushion:",
                            subtitle: "Ensure you are within 10 feet of the cushion to connect",
                            image: UIImage(named: "proximity")
                        ),
                        WhatsNew.Item(
                            title: "Questions?",
                            subtitle: "Email us at support@guardianangelcushion.com",
                            image: UIImage(named: "question")
                        )
                    ]
                )
            }

            let myTheme = WhatsNewViewController.Theme { configuration in
                configuration.titleView.titleColor = .white
                configuration.backgroundColor = standardColor
                configuration.itemsView.titleFont = .boldSystemFont(ofSize: 22)
                configuration.itemsView.titleColor = .white
                configuration.itemsView.subtitleFont = .systemFont(ofSize: 13.2)
                configuration.itemsView.subtitleColor = .white
                configuration.completionButton.title = "Go Back"
                configuration.completionButton.backgroundColor = .white
                configuration.completionButton.titleColor = standardColor
            }
            
            let configuration = WhatsNewViewController.Configuration(
                theme: myTheme
            )
            guard let new = whatsNew else { fatalError() }
            let whatsNewViewController = WhatsNewViewController(
                whatsNew: new,
                configuration: configuration
            )
            
            present(whatsNewViewController, animated: true)
        }
        /// Device Info Button Setup
        @objc func goToDeviceInfoView() {
            let whatsNew = WhatsNew(
                title: "Information about Device",
                items: [
                    WhatsNew.Item(
                        title: "Temperature Section:",
                        subtitle: "The temperature calculated by the smart cushion",
                        image: UIImage(named: "temp_image")
                    ),
                    WhatsNew.Item(
                        title: "Proximity from Cushion Section:",
                        subtitle: "Provides information about the proximity of the user from the smart cushion",
                        image: UIImage(named: "proximity")
                    ),
                    WhatsNew.Item(
                        title: "Weight Detected Section:",
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
                configuration.backgroundColor = standardColor
                configuration.itemsView.titleFont = .boldSystemFont(ofSize: 22)
                configuration.itemsView.titleColor = .white
                configuration.itemsView.subtitleFont = .systemFont(ofSize: 13.2)
                configuration.itemsView.subtitleColor = .white
                configuration.completionButton.title = "Go Back"
                configuration.completionButton.backgroundColor = .white
                configuration.completionButton.titleColor = standardColor
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
