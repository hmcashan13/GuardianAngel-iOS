//
//  SettingsController.swift
//  GuardianAngel
//
//  Created by Hudson Mcashan on 1/13/18.
//  Copyright © 2018 Hudson Mcashan. All rights reserved.
//

import UIKit
import Firebase

class SettingsViewController: UITableViewController, UINavigationControllerDelegate {
    
    //let cellNames = [ "Adjust Temperature Sensor","Change Email","Change Profile Picture", "Change Password", "Delete Account"]
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
    
    lazy var profileImage: UIImageView = {
        let imageView = UIImageView()
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectProfileImageView)))
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
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
//        if indexPath.row == 1 {
//            changeEmail()
//        }
//        if indexPath.row == 2 {
//            changeProfilePicture()
//        }
//        if indexPath.row == 3 {
//            changePassword()
//        }
//        if indexPath.row == 4 {
//            deleteAccount()
//        }
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
    
    /////////// FUTURE FUNCTIONS WITH AUTHENTICATION SETUP ////////////

    // 2
    func changeEmail() {
        var newEmail: String?
        
        let currentEmail = Auth.auth().currentUser?.email
        if let email = currentEmail {
            let alert = UIAlertController(title: "Change Email", message: "\(email) is your current email address", preferredStyle: .alert)
            
            alert.addTextField { (textField) in
                textField.text = ""
            }

            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields?.first // Force unwrapping because we know it exists.
                newEmail = textField?.text ?? "nothing"
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Oops", message: "There was a problem loading your email address", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
        }
        
        
        
        guard let email = newEmail else {
            let alert = UIAlertController(title: "Oops", message: "The email you entered was not valid", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            return
        }
        Auth.auth().currentUser?.updateEmail(to: email) { (error) in
            print(error ?? "error")
            return
        }
    }
    
    // 3
    func changeProfilePicture() {
        handleSelectProfileImageView()
    }
    
    // 4
    func changePassword() {
        let user = Auth.auth().currentUser
        if let email = user?.email {
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                print("Password reset email sent")
                let alert = UIAlertController(title: "Email Sent", message: "An email has been sent to \(email) in order to reset your password", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // 5
    func deleteAccount() {
        let user = Auth.auth().currentUser
        
        user?.delete { error in
            if (error != nil) {
                let alert = UIAlertController(title: "Error", message: "There was a problem deleting your account", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                self.handleCancel()
                self.handleLogout()
            }
        }
    }
    
    func handleLogout() {
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        let loginViewController = LoginViewController()
        let navController = UINavigationController(rootViewController: loginViewController)
        
        DispatchQueue.main.async {
            self.present(navController, animated: true, completion: nil)
        }
    }
    
    
}

// MARK: ImagePickerController extension
extension SettingsViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImage.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc func handleSelectProfileImageView() {
        let picker = UIImagePickerController()
        
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("canceled picker")
        dismiss(animated: true, completion: nil)
    }
}
