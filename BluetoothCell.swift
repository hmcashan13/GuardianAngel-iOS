//
//  BluetoothCell.swift
//  GuardianAngel
//
//  Created by Hudson Mcashan on 1/24/18.
//  Copyright © 2018 Hudson Mcashan. All rights reserved.
//
import UIKit
import Foundation

class BluetoothCell: UITableViewCell {
    let peripheralLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.contentMode = .scaleAspectFill
        return label
    }()
    let rssiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.contentMode = .scaleAspectFill
        return label
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        addSubview(peripheralLabel)
        //need x,y,width,height anchors
        peripheralLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        peripheralLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive=true
        peripheralLabel.widthAnchor.constraint(equalToConstant: 200).isActive = true
        peripheralLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        addSubview(rssiLabel)
        
        //need x,y,width,height anchors
        rssiLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 8).isActive = true
        rssiLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive=true
        rssiLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
