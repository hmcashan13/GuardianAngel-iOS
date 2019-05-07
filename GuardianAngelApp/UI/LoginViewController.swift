//
//  LoginViewController.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 10/17/18.
//  Copyright © 2018 Guardian Angel. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn

class LoginViewController: UIViewController, GIDSignInUIDelegate {
    let logoContainerView: UIView = {
        let view = UIView()
    
        let image = UIImage(named: "GUARDIAN ANGEL - LOGO 2 - white")
        let logoImageView = UIImageView(image: image)
        logoImageView.contentMode = .scaleAspectFill
        
        view.addSubview(logoImageView)
        logoImageView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 200, height: 100)
        logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 10).isActive = true
       
        view.backgroundColor = UIColor.purple
        
        return view
    }()
    
    let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.autocapitalizationType = UITextAutocapitalizationType.none
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        
        return tf
    }()
    
    let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.isSecureTextEntry = true
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    // Change login button colors when both text fields have text
    @objc func handleTextInputChange() {
        let isFormValid = emailTextField.text?.isEmpty == false && passwordTextField.text?.isEmpty == false
        
        if isFormValid {
            loginButton.isEnabled = true
            loginButton.backgroundColor = UIColor.purple
            loginButton.layer.cornerRadius = 5
            loginButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            loginButton.setTitleColor(.white, for: .normal)
        } else {
            loginButton.isEnabled = false
            loginButton.backgroundColor = UIColor.white
            loginButton.setTitleColor(UIColor.purple, for: .normal)
        }
    }
    
    let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.backgroundColor = UIColor.white
        button.setTitleColor(UIColor.purple, for: .normal)
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.purple.cgColor

        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        
        button.isEnabled = false
        
        return button
    }()
    
    // Create facebook and google login buttons
    let facebookLoginButton = FBSDKLoginButton()
    let googleLoginButton = UIButton()
    
    let dontHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        
        let attributedTitle = NSMutableAttributedString(string: "Don't have an account?  ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        attributedTitle.append(NSAttributedString(string: "Sign Up", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.purple
            ]))
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        button.addTarget(self, action: #selector(handleShowSignUp), for: .touchUpInside)
        return button
    }()
    
    @objc private func handleLogin() {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        Auth.auth().signIn(withEmail: email, password: password, completion: {
            if let err = $1 {
                Utils.showAlertMessage(presenter: self, title: "Login Failed", message: "Email/Password combination was incorrect")

                print("Failed to sign in with email:", err)
                return
            }
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    @objc func handleShowSignUp() {
        let signUpController = RegisterViewController()
        navigationController?.pushViewController(signUpController, animated: true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup keyboard so you can dismiss it when you tap anywhere outside of it
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // Setup UI
        navigationController?.isNavigationBarHidden = true
    
        view.backgroundColor = .white
        
        setupLogo()
        setupInputFields()
        setupFacebookLoginButton()
        setupGoogleLoginButton()
        setupRegisterButton()
        setupKeyboardObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if checkIfUserLoggedIn() {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func checkIfUserLoggedIn() -> Bool {
        if let uid = Auth.auth().currentUser?.uid {
            // Logged in with Firebase
            print("Successfully logged into Firebase through email (uid): ", uid)
            return true
        } else if FBSDKAccessToken.currentAccessTokenIsActive() {
            // Logged in with Facebook
            print("Successfully logged into Firebase through Facebook")
            return true
        } else if let shared = GIDSignIn.sharedInstance(), shared.hasAuthInKeychain() {
            print("Successfully logged into Firebase through Google")
            return true
        } else {
            // Not logged in
            print("Not logged in")
            return false
        }
    }
    
    // UI setup functions
    private func setupLogo() {
        view.addSubview(logoContainerView)
        logoContainerView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 200)
    }
    
    private func setupInputFields() {
        // Setup email, password, and login text views
        let stackView = UIStackView(arrangedSubviews: [emailTextField, passwordTextField, loginButton])
        
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        
        view.addSubview(stackView)
        stackView.anchor(top: logoContainerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 40, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 140)
        
    }
    
    private func setupFacebookLoginButton() {
        // Setup read permissions for Facebook login
        facebookLoginButton.readPermissions = ["public_profile", "email"];
        // Setup UI
        view.addSubview(facebookLoginButton)
        facebookLoginButton.translatesAutoresizingMaskIntoConstraints = false
        facebookLoginButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        facebookLoginButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
        facebookLoginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        facebookLoginButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 40).isActive = true
    }
    
    private func setupGoogleLoginButton() {
        //add google sign in button
        view.addSubview(googleLoginButton)
        googleLoginButton.translatesAutoresizingMaskIntoConstraints = false
        googleLoginButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        googleLoginButton.widthAnchor.constraint(equalToConstant: 180).isActive = true
        googleLoginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        googleLoginButton.topAnchor.constraint(equalTo: facebookLoginButton.bottomAnchor, constant: 20).isActive = true
        
        googleLoginButton.addTarget(self, action: #selector(loginWithGoogle), for: .touchUpInside)
        googleLoginButton.setImage(UIImage(named: "btn_google_light_normal_ios"), for: .normal)
        googleLoginButton.setTitle("    Login with Google   ", for: .normal)
        googleLoginButton.setTitleColor(.black, for: .normal)
        googleLoginButton.titleLabel?.font = UIFont(name: "Helvetica", size: 13.0)
        googleLoginButton.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        googleLoginButton.layer.cornerRadius = 3
        // Setup Google sign-in delegate
        GIDSignIn.sharedInstance().uiDelegate = self
    }
    
    @objc func loginWithGoogle() {
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    private func setupRegisterButton() {
        view.addSubview(dontHaveAccountButton)
        dontHaveAccountButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
    }
    
    // Functions to setup dismissing keyboard when tapping outside of it
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func handleKeyboardWillShow(_ notification: Notification) {
        _ = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        let keyboardDuration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        UIView.animate(withDuration: keyboardDuration!, animations: {
            
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func handleKeyboardWillHide(_ notification: Notification) {
        let keyboardDuration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        UIView.animate(withDuration: keyboardDuration!, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
}

