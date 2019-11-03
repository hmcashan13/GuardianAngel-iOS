//
//  TemperatureAdjustViewController.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 11/7/18.
//  Copyright © 2018 Guardian Angel. All rights reserved.
//

import UIKit
import WhatsNewKit

public let tempSensorOn = Notification.Name("tempSensorOn")
public let tempSensorOff = Notification.Name("tempSensorOff")

class TemperatureAdjustViewController: UIViewController, UINavigationControllerDelegate {
    let step:Float = 1  // If you want UISlider to snap to steps by 5
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Adjust Temperature Sensor"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Info", style: .plain, target: self, action: #selector(goToTempInfo))
        view.backgroundColor = standardColor
        setupUIConstraints()
    }
    
    private let inputsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    private let tempSwitchTextLabel: UILabel = {
        let label = UILabel()
        label.text = "Temperature Sensor On/Off:"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tempSwitch: UISwitch = {
        let tempOnOff = UISwitch()
        tempOnOff.addTarget(self, action: #selector(switchStateDidChange(_:)), for: .valueChanged)
        if AppDelegate.is_temp_enabled {
            tempOnOff.setOn(true, animated: true)
        } else {
            tempOnOff.setOn(false, animated: true)
        }
        tempOnOff.translatesAutoresizingMaskIntoConstraints = false
        return tempOnOff
    }()
    
    private let seperatorView1: UIView = {
        let view = UIView()
        view.backgroundColor = standardColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let metricOrNahTextLabel: UILabel = {
        let label = UILabel()
        label.text = "Farenheit or Celcius?"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let degreeTypeSegCntrl: UISegmentedControl = {
        let temps = ["°F","°C"]
        let segCntrl = UISegmentedControl(items: temps)
        segCntrl.selectedSegmentIndex = AppDelegate.farenheit_celsius ? 0 : 1
        segCntrl.addTarget(self, action: #selector(farenheitOrCelsius), for: .valueChanged)
        segCntrl.translatesAutoresizingMaskIntoConstraints = false
        return segCntrl
    }()
    
    private let seperatorView2: UIView = {
        let view = UIView()
        view.backgroundColor = standardColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let sliderLabel: UILabel = {
        let label = UILabel()
        if AppDelegate.farenheit_celsius {
            label.text = "\(AppDelegate.max_temp)°F"
        } else {
            let celsius = (AppDelegate.max_temp - 32)*5/9
            label.text =  "\(celsius)°C"
        }
        
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let maxTempTextLabel: UILabel = {
        let label = UILabel()
        label.text = "Max Temperature:"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let mySlider: UISlider = {
        let slider = UISlider(frame:CGRect(x: 10, y: 100, width: 300, height: 20))
        slider.minimumValue = 80
        slider.maximumValue = 100
        slider.isContinuous = true
        slider.setValue(Float(AppDelegate.max_temp), animated: false)
        slider.tintColor = UIColor.blue
        slider.addTarget(self, action: #selector(sliderValueDidChange(_:)), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    private func setupUIConstraints() {
        view.addSubview(inputsContainerView)
        view.addSubview(mySlider)
        // setup constraints for container
        inputsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive=true
        inputsContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive=true
        inputsContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive=true
        inputsContainerView.heightAnchor.constraint(equalToConstant: 180).isActive=true
        
        // setup constrains for slider
        mySlider.topAnchor.constraint(equalTo: inputsContainerView.bottomAnchor, constant: 20).isActive=true
        mySlider.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive=true
        mySlider.widthAnchor.constraint(equalToConstant: 300).isActive=true
        mySlider.heightAnchor.constraint(equalToConstant: 20).isActive=true
        
        // add items into container view
        inputsContainerView.addSubview(maxTempTextLabel)
        inputsContainerView.addSubview(sliderLabel)
        inputsContainerView.addSubview(seperatorView1)
        inputsContainerView.addSubview(metricOrNahTextLabel)
        inputsContainerView.addSubview(degreeTypeSegCntrl)
        inputsContainerView.addSubview(seperatorView2)
        inputsContainerView.addSubview(tempSwitchTextLabel)
        inputsContainerView.addSubview(tempSwitch)
        
        // setup contraints for items in container view
        tempSwitchTextLabel.topAnchor.constraint(equalTo: inputsContainerView.topAnchor, constant: 20).isActive=true
        tempSwitchTextLabel.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 20).isActive=true
        
        tempSwitch.topAnchor.constraint(equalTo: inputsContainerView.topAnchor, constant: 15).isActive=true
        tempSwitch.rightAnchor.constraint(equalTo: inputsContainerView.rightAnchor, constant: -20).isActive=true
       
        seperatorView1.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive=true
        seperatorView1.topAnchor.constraint(equalTo: tempSwitchTextLabel.bottomAnchor, constant: 20).isActive=true
        seperatorView1.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive=true
        seperatorView1.heightAnchor.constraint(equalToConstant: 1).isActive=true
        
        metricOrNahTextLabel.topAnchor.constraint(equalTo: seperatorView1.bottomAnchor, constant: 20).isActive=true
        metricOrNahTextLabel.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 20).isActive=true
        
        degreeTypeSegCntrl.topAnchor.constraint(equalTo: seperatorView1.bottomAnchor, constant: 17).isActive=true
        degreeTypeSegCntrl.rightAnchor.constraint(equalTo: inputsContainerView.rightAnchor, constant: -20).isActive=true
        
        seperatorView2.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor).isActive=true
        seperatorView2.topAnchor.constraint(equalTo: metricOrNahTextLabel.bottomAnchor, constant: 20).isActive=true
        seperatorView2.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive=true
        seperatorView2.heightAnchor.constraint(equalToConstant: 1).isActive=true
        
        maxTempTextLabel.topAnchor.constraint(equalTo: seperatorView2.bottomAnchor, constant: 20).isActive=true
        maxTempTextLabel.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 20).isActive=true
        
        sliderLabel.topAnchor.constraint(equalTo: seperatorView2.bottomAnchor, constant: 20).isActive=true
        sliderLabel.rightAnchor.constraint(equalTo: inputsContainerView.rightAnchor, constant: -20).isActive=true
    }
    
    
    
    @objc func farenheitOrCelsius() {
        let farenheit_celsius = AppDelegate.farenheit_celsius
        AppDelegate.farenheit_celsius = !farenheit_celsius
        if isDebugging {
            print("New temp setting: ", AppDelegate.farenheit_celsius)
        }
        let sliderValue = mySlider.value
        let farenheitIntValue = Int(sliderValue)
        if AppDelegate.farenheit_celsius {
            sliderLabel.text = "\(farenheitIntValue)°F"
            if isDebugging {
                print("new farenheit max temp: ", farenheitIntValue)
            }
        } else {
            let celsiusIntValue = ((farenheitIntValue-32)*5/9)
            sliderLabel.text = "\(celsiusIntValue)°C"
            if isDebugging {
                print("new celsius max temp: ", celsiusIntValue)
            }
        }
        AppDelegate.max_temp = farenheitIntValue
        defaults.set(farenheitIntValue, forKey: max_temp_key)
    }
    
    @objc func switchStateDidChange(_ sender:UISwitch!) {
        let enabled = sender.isOn ? true : false
        if isDebugging {
            print("is temp enabled: ", enabled)
        }
        AppDelegate.is_temp_enabled = enabled
        defaults.set(enabled, forKey: is_temp_enabled_key)
    }
    
    @objc func sliderValueDidChange(_ sender:UISlider!) {
        // Use this code below only if you want UISlider to snap to values step by step
        let roundedStepValue = round(sender.value / step) * step
        sender.value = roundedStepValue
        let farenheitIntValue = Int(roundedStepValue)
        if AppDelegate.farenheit_celsius {
            sliderLabel.text = "\(farenheitIntValue)°F"
        } else {
            let celsiusIntValue = (farenheitIntValue - 32)*5/9
            sliderLabel.text = "\(celsiusIntValue)°C"
        }
        AppDelegate.max_temp = farenheitIntValue
        defaults.set(farenheitIntValue, forKey: max_temp_key)
    }
    
    @objc func goToTempInfo() {
        let whatsNew = WhatsNew(
            title: "Adjust Temperature Settings",
            items: [
                WhatsNew.Item(
                    title: "Temp Sensor On/Off Section:",
                    subtitle: "While this is on, you will temperature data from the cushion and notifications from the app. Otherwise you will not receive either of these things",
                    image: UIImage(named: "setup")
                ),
                WhatsNew.Item(
                    title: "Farenheit or Celsius Section:",
                    subtitle: "Sets the temperature to Farenheit or Celsius",
                    image: UIImage(named: "fahrenheit_celsius")
                ),
                WhatsNew.Item(
                    title: "Max Temperature Section:",
                    subtitle: "The temperature that will trigger you to receive notifications from the app. This can be adjusted using the slider below",
                    image: UIImage(named: "temp")
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
        
        self.present(whatsNewViewController, animated: true)
    }
}

extension String {
    func farenheitToCelsius() -> String? {
        guard let fahrenheitTemp = Double(self) else { return nil }
        let roundedTemp: Int = Int((fahrenheitTemp - 32)*5/9)
        let celsiusTemp: String = String(roundedTemp)
        return "\(celsiusTemp)"
    }
    
    func celsiusToFarenheit() -> String? {
        guard let celsiusTemp: Double = Double(self) else { return nil }
        let roundedTemp: Int = Int(celsiusTemp * 9/5 + 32)
        let fahrenheitTemp: String = String(roundedTemp)
        return "\(fahrenheitTemp)"
    }
}
