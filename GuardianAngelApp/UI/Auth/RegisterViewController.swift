//
//  RegisterViewController.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 10/17/18.
//  Copyright © 2018 Guardian Angel. All rights reserved.
//


import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

protocol RegisterDelegate: AnyObject {
    func setTitle(_ title: String)
}

class RegisterViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo_purple")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        
        return imageView
    }()
    
    let nameTextField: UITextField = {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(string: "Name",
                                                      attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        tf.textColor = UIColor.black
        tf.autocorrectionType = .no
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        
        return tf
    }()
    
    let emailTextField: UITextField = {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(string: "Email",
                                                      attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        tf.textColor = UIColor.black
        tf.autocapitalizationType = UITextAutocapitalizationType.none
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        
        return tf
    }()
    
    // Change register button colors when both text fields have text
    @objc func handleTextInputChange() {
        let isFormValid = nameTextField.text?.isEmpty == false && emailTextField.text?.isEmpty == false && confirmPasswordTextField.text?.isEmpty == false && passwordTextField.text?.isEmpty == false
        
        if isFormValid {
            signUpButton.isEnabled = true
            signUpButton.backgroundColor = standardColor
            signUpButton.layer.cornerRadius = 5
            signUpButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            signUpButton.setTitleColor(.white, for: .normal)
        } else {
            signUpButton.isEnabled = false
            signUpButton.backgroundColor = UIColor.white
            signUpButton.setTitleColor(standardColor, for: .normal)
        }
    }
    
    let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(string: "Password",
                                                      attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        tf.textColor = UIColor.black
        tf.isSecureTextEntry = true
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    let confirmPasswordTextField: UITextField = {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(string: "Confirm Password",
                                                      attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        tf.textColor = UIColor.black
        tf.isSecureTextEntry = true
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(standardColor, for: .normal)
        button.layer.borderColor = standardColor.cgColor
        button.layer.borderWidth = 2
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        
        button.isEnabled = false
        
        return button
    }()
    
    @objc func handleSignUp() {
        guard let name = nameTextField.text, let email = emailTextField.text, let password = passwordTextField.text, let confirmPassword = confirmPasswordTextField.text, !name.isEmpty, !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else { return }
        
        guard confirmPassword == password else {
            showAlertMessage(presenter: self, title: "Alert", message: "Passwords do not match", handler: nil)
            
            return
        }
        Auth.auth().createUser(withEmail: email, password: password, completion: { (result, error: Error?) in
            if let error = error {
                // TODO: handle error
                print("Failed to create user:", error)
                let alert = UIAlertController(title: "Alert", message: error.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
                
                return
            }
            let user = Auth.auth().currentUser
            if let user = user {
                let changeRequest = user.createProfileChangeRequest()
                
                changeRequest.displayName = name
                changeRequest.commitChanges { error in
                    if let error = error {
                        // TODO: handle error
                    } else {
                    
                    }
                }
            }
            
            if let result = result {
                // Registration Succsesful
                if let email = result.user.email, let name = result.user.displayName  {
                    let id = result.user.providerID
                    // Present success message to user with email
                    self.dismissKeyboard()
                    showAlertMessage(presenter: self, title: "Registration Successful", message: "Now logging you in with your email: \(email)", handler: {
                        // Setup UI for Device VC
                        self.registerDelegate?.setTitle("\(name)")
                        // Setup State
                        AppDelegate.user = LocalUser(id: id, name: name, email: email)
                        // Dismiss Register VC
                        self.dismiss(animated: true, completion: nil)
                    })
                } else {
                    // Present success message to user w/o email
                    showAlertMessage(presenter: self, title: "Registration Successful", message: "Now login with your email", handler: {
                        // Logout
                        do {
                            try Auth.auth().signOut()
                        } catch let logoutError {
                            // TODO: handle error
                            print("Logout error: ", logoutError)
                        }
                        // Go back to login page
                        self.popRegisterVC()
                    })
                }
            }
            
        })
    }
    
    weak var registerDelegate: RegisterDelegate?
    
    let alreadyHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        
        let attributedTitle = NSMutableAttributedString(string: "Already have an account?  ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        attributedTitle.append(NSAttributedString(string: "Sign In", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: standardColor
            ]))
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        button.addTarget(self, action: #selector(popRegisterVC), for: .touchUpInside)
        return button
    }()
    
    @objc func popRegisterVC() {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
        
        view.backgroundColor = .white
        
        view.addSubview(logoImageView)
        
        logoImageView.anchor(top: view.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 40, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 90, height: 90)
        
        logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        setupInputFields()
    }
    
    fileprivate func setupInputFields() {
        let stackView = UIStackView(arrangedSubviews: [nameTextField, emailTextField, passwordTextField, confirmPasswordTextField, signUpButton])
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 10
        
        view.addSubview(stackView)
        
        stackView.anchor(top: logoImageView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 250)
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
}

extension UIView {
    func anchor(top: NSLayoutYAxisAnchor?, left: NSLayoutXAxisAnchor?, bottom: NSLayoutYAxisAnchor?, right: NSLayoutXAxisAnchor?,  paddingTop: CGFloat, paddingLeft: CGFloat, paddingBottom: CGFloat, paddingRight: CGFloat, width: CGFloat, height: CGFloat) {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            self.topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
        }
        
        if let left = left {
            self.leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
        }
        
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: paddingBottom).isActive = true
        }
        
        if let right = right {
            rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
        }
        
        if width != 0 {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        
        if height != 0 {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }

    
}
