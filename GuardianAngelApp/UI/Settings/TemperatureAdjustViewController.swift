//
//  TemperatureAdjustViewController.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 11/7/18.
//  Copyright © 2018 Guardian Angel. All rights reserved.
//

import UIKit

public let tempSensorOn = Notification.Name("tempSensorOn")
public let tempSensorOff = Notification.Name("tempSensorOff")

class TemperatureAdjustViewController: UIViewController, UINavigationControllerDelegate {
    let step:Float = 5  // If you want UISlider to snap to steps by 5
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Adjust Temperature Sensor"
        view.backgroundColor = UIColor.purple
        navigationItem.rightBarButtonItem = infoButton
        setupUIConstraints()
    }
    
    let infoButton: UIBarButtonItem = {
        let button = UIButton()
        button.setImage(UIImage(named: "info"), for: .normal)
        button.addTarget(self, action: #selector(showTempInfo), for: .touchUpInside)
        let barButton = UIBarButtonItem(customView: button)
        return barButton
    }()
    
    let inputsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    let tempSwitchTextLabel: UILabel = {
        let label = UILabel()
        label.text = "Temperature Sensor On/Off:"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let tempSwitch: UISwitch = {
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
    
    let seperatorView1: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.rgb(red: 220, green: 91, blue: 151)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let metricOrNahTextLabel: UILabel = {
        let label = UILabel()
        label.text = "Celcius or Farenheit?"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let degreeTypeSegCntrl: UISegmentedControl = {
        let temps = ["°F","°C"]
        let segCntrl = UISegmentedControl(items: temps)
        segCntrl.selectedSegmentIndex = AppDelegate.farenheit_celsius ? 0 : 1
        segCntrl.addTarget(self, action: #selector(farenheitOrCelsius), for: .valueChanged)
        segCntrl.translatesAutoresizingMaskIntoConstraints = false
        return segCntrl
    }()
    
    let seperatorView2: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.rgb(red: 220, green: 91, blue: 151)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let sliderLabel: UILabel = {
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
    
    let maxTempTextLabel: UILabel = {
        let label = UILabel()
        label.text = "Max Temperature:"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let mySlider: UISlider = {
        let slider = UISlider(frame:CGRect(x: 10, y: 100, width: 300, height: 20))
        slider.minimumValue = 60
        slider.maximumValue = 100
        slider.isContinuous = true
        slider.setValue(Float(AppDelegate.max_temp), animated: false)
        slider.tintColor = UIColor.blue
        slider.addTarget(self, action: #selector(sliderValueDidChange(_:)), for: .valueChanged)
        return slider
    }()
    
    func setupUIConstraints() {
        view.addSubview(inputsContainerView)
        view.addSubview(mySlider)
        mySlider.center = view.center
        //setup x, y, width, height constraints of inputs container view
        inputsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive=true
        inputsContainerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 150).isActive=true
        inputsContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive=true
        inputsContainerView.heightAnchor.constraint(equalToConstant: 180).isActive=true
        
        inputsContainerView.addSubview(maxTempTextLabel)
        inputsContainerView.addSubview(sliderLabel)
        inputsContainerView.addSubview(seperatorView1)
        inputsContainerView.addSubview(metricOrNahTextLabel)
        inputsContainerView.addSubview(degreeTypeSegCntrl)
        inputsContainerView.addSubview(seperatorView2)
        inputsContainerView.addSubview(tempSwitchTextLabel)
        inputsContainerView.addSubview(tempSwitch)
        
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
    
    @objc func showTempInfo() {
        // view to give details on what these settings mean
    }
    
    @objc func farenheitOrCelsius() {
        let farenheit_celsius = AppDelegate.farenheit_celsius
        AppDelegate.farenheit_celsius = !farenheit_celsius
        print("New temp setting: ", AppDelegate.farenheit_celsius)
        let sliderValue = mySlider.value
        let farenheitIntValue = Int(sliderValue)
        if AppDelegate.farenheit_celsius {
            sliderLabel.text = "\(farenheitIntValue)°F"
            print("new farenheit max temp: ", farenheitIntValue)
        } else {
            let celsiusIntValue = ((farenheitIntValue-32)*5/9)
            sliderLabel.text = "\(celsiusIntValue)°C"
            print("new celsius max temp: ", celsiusIntValue)
        }
        AppDelegate.max_temp = farenheitIntValue
        defaults.set(farenheitIntValue, forKey: max_temp_key)
    }
    
    @objc func switchStateDidChange(_ sender:UISwitch!) {
        let enabled = sender.isOn ? true : false
        print("is temp enabled: ", enabled)
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
}

extension String {
    func farenheitToCelsius() -> String {
        guard let tempString = Int(self) else { return "invalid" }
        let converted = String((tempString - 32)*5/9)
        return "\(converted)˚C"
    }
    
    func celsiusToFarenheit() -> String {
        guard let tempString = Int(self) else { return "invalid" }
        let converted = String(tempString * 9/5 + 32)
        return "\(converted)˚F"
    }
}
