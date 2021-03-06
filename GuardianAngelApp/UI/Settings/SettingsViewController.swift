//
//  SettingsController.swift
//  GuardianAngel
//
//  Created by Hudson Mcashan on 1/13/18.
//  Copyright © 2018 Hudson Mcashan. All rights reserved.
//

import UIKit

protocol SettingsDelegate: AnyObject {
    func backgroundScan()
    func disconnectDevice()
}

class SettingsViewController: UITableViewController, UINavigationControllerDelegate {
    weak var delegate: SettingsDelegate?
    
    private let cellNames = ["Adjust Temperature Sensor", "Reconnect to Cushion", "Disconnect From Cushion"]
    private let cellID = "cellID"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Settings"
        
        view.backgroundColor = standardColor
        
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
        if indexPath.row == 0 || indexPath.row == 1 {
            cell.accessoryType = .disclosureIndicator
            cell.accessoryType = .disclosureIndicator
        }
        cell.textLabel?.textColor = UIColor.white
        cell.backgroundColor = standardColor
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            adjustTemp()
        case 1:
            reconnectDevice()
        case 2:
            disconnectDevice()
        default:
            print("nothing")
        }
    }
    
    // MARK: TableView Functions
    // 1
    private func adjustTemp() {
        let tempVC = TemperatureAdjustViewController()
        self.navigationController?.pushViewController(tempVC, animated: true)
    }
    // 2
    private func reconnectDevice() {
        delegate?.backgroundScan()
    }
    
    // 3
    private func disconnectDevice() {
        delegate?.disconnectDevice()
    }
}
