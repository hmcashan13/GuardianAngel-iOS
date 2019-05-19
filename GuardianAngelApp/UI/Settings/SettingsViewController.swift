//
//  SettingsController.swift
//  GuardianAngel
//
//  Created by Hudson Mcashan on 1/13/18.
//  Copyright © 2018 Hudson Mcashan. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController, UINavigationControllerDelegate {
    
    let cellNames = ["Adjust Temperature Sensor","Disconnect From Cushion"]
    let cellID = "cellID"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Settings"
        
        view.backgroundColor = UIColor(displayP3Red: 0.698, green: 0.4, blue: 1.0, alpha: 1.0)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        
        tableView.tableFooterView = UIView(frame: .zero)
    }
    @objc func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: TableView
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellNames.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        cell.textLabel?.text = cellNames[indexPath.row]
        if indexPath.row == 0 {
            cell.accessoryType = .disclosureIndicator
        }
        cell.textLabel?.textColor = UIColor.white
        cell.backgroundColor = UIColor(displayP3Red: 0.698, green: 0.4, blue: 1.0, alpha: 1.0)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            adjustTemp()
        }
        if indexPath.row == 1 {
            disconnect()
        }
    }
    // MARK: Functions
    
    // 1
    func adjustTemp() {
        let tempVC = TemperatureAdjustViewController()
        self.navigationController?.pushViewController(tempVC, animated: true)
    }
    
    // 2
    func disconnect() {
        
    }
}
