//
//  LoginViewController.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 10/17/18.
//  Copyright © 2018 Guardian Angel. All rights reserved.
//

import UIKit
import FirebaseAuth
import FacebookLogin
import FacebookCore
import GoogleSignIn

protocol LoginDelegate: AnyObject {
    func setTitle(_ title: String)
}

class LoginViewController: UIViewController, RegisterDelegate {
    func setTitle(_ title: String) {
        self.loginDelegate?.setTitle(title)
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
    
    weak var loginDelegate: LoginDelegate?
    let logoContainerView: UIView = {
        let view = UIView()
    
        let image = UIImage(named: "logo_white")
        let logoImageView = UIImageView(image: image)
        logoImageView.contentMode = .scaleAspectFill
        
        view.addSubview(logoImageView)
        logoImageView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 200, height: 100)
        logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 10).isActive = true
       
        view.backgroundColor = standardColor
        
        return view
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
    
    // Change login button colors when both text fields have text
    @objc func handleTextInputChange() {
        let isFormValid = emailTextField.text?.isEmpty == false && passwordTextField.text?.isEmpty == false
        
        if isFormValid {
            loginButton.isEnabled = true
            loginButton.backgroundColor = standardColor
            loginButton.layer.cornerRadius = 5
            loginButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            loginButton.setTitleColor(.white, for: .normal)
        } else {
            loginButton.isEnabled = false
            loginButton.backgroundColor = UIColor.white
            loginButton.setTitleColor(standardColor, for: .normal)
        }
    }
    
    let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.backgroundColor = UIColor.white
        button.setTitleColor(standardColor, for: .normal)
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 2
        button.layer.borderColor = standardColor.cgColor

        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        
        button.isEnabled = false
        
        return button
    }()
    
    // Create facebook and google login buttons
    let facebookLoginButton = FBLoginButton()
    let googleLoginButton = UIButton()
    
    let dontHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        
        let attributedTitle = NSMutableAttributedString(string: "Don't have an account?  ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        attributedTitle.append(NSAttributedString(string: "Sign Up", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: standardColor
            ]))
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        button.addTarget(self, action: #selector(handleShowSignUp), for: .touchUpInside)
        return button
    }()
    
    // Firebase Login
    @objc private func handleLogin() {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        Auth.auth().signIn(withEmail: email, password: password, completion: { result, error in
            if let error = error {
                // Email/Password wrong
                showAlertMessage(presenter: self, title: "Login Failed", message: "Email/Password combination was incorrect", handler: nil)

                print("There was a problem logging in:", error)
                return
            } else {
                if let result = result {
                    // Login successful
                    let uid = result.user.uid
                    let name = result.user.displayName
                    let email = result.user.email
                    // Setup UI
                    self.loginDelegate?.setTitle(name ?? "")
                    // Setup user
                    AppDelegate.user = LocalUser(id: uid, name: name ?? "", email: email)
                    
                    self.dismiss(animated: true, completion: nil)
                } else {
                    // Error Logging In
                    showAlertMessage(presenter: self, title: "Login Failed", message: "There was a problem logging in", handler: nil)

                    print("ERROR: RESULT WAS NIL")
                }
            }
            
            
            
        })
    }
    
    @objc func handleShowSignUp() {
        let signUpController = RegisterViewController()
        signUpController.registerDelegate = self
        navigationController?.pushViewController(signUpController, animated: true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    
    private func checkIfUserLoggedIn() -> Bool {
        if let user = Auth.auth().currentUser {
            // Logged in with Firebase
            let uid = user.uid
            if isDebugging {
                print("Successfully logged into Firebase through email (uid): ", user.uid)
            }
            self.loginDelegate?.setTitle(user.displayName ?? "")
            AppDelegate.user = LocalUser(id: uid, name: user.displayName ?? "", email: user.email)
            return true
        } else if AccessToken.isCurrentAccessTokenActive {
            // Logged in with Facebook
            if isDebugging {
                print("Successfully logged into Firebase through Facebook")
            }
            // TODO: ensure the title is set
            return true
        } else if let shared = GIDSignIn.sharedInstance(), shared.hasPreviousSignIn() {
            // Logged in with Google
            if isDebugging {
                print("Successfully logged into Firebase through Google")
            }
            // TODO: ensure the title is set
            return true
        } else {
            // Not logged in so stay here
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
        facebookLoginButton.permissions = ["public_profile", "email"]
        // Setup FBLoginButton delegate
        facebookLoginButton.delegate = self
        // Setup UI
        view.addSubview(facebookLoginButton)
        facebookLoginButton.translatesAutoresizingMaskIntoConstraints = false
        //facebookLoginButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        facebookLoginButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
        facebookLoginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        facebookLoginButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 40).isActive = true
    }
    
    private func setupGoogleLoginButton() {
        // Setup Google sign-in delegate
        GIDSignIn.sharedInstance()?.delegate = self
        // Setup to allow presenting of Login Web View
        GIDSignIn.sharedInstance()?.presentingViewController = self
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
    }
    
    @objc func loginWithGoogle() {
        guard let signIn = GIDSignIn.sharedInstance() else {
            showAlertMessage(presenter: self, title: "Login Error", message: "There was a problem logging in with Google", handler: nil)
            return
        }
        signIn.signIn()
    }

    private func setupRegisterButton() {
        view.addSubview(dontHaveAccountButton)
        dontHaveAccountButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)
    }
    
    
}

extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // TODO
    }
    
    // Facebook Login Button
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let result = result, let token = result.token else {
            // TODO: Handle error
            print("Failed logging in with Facebook")
            return
        }
        let req = GraphRequest(graphPath: "me", parameters: ["fields":"email,name"], tokenString: token.tokenString, version: nil, httpMethod: HTTPMethod(rawValue: "GET"))

        req.start { (connection, result, error) in
            if let error = error {
                showAlertMessage(presenter: self, title: "Facebook Login Failed", message: "Attempt to Login via Facebook did not work", handler: nil)
                print("Facebook error: \(error.localizedDescription)")
                return
            } else {
                if let delegate = self.loginDelegate, let dict = result as? NSDictionary, let id = dict["id"] as? String  {
                    let name = dict["name"] as? String
                    let email = dict["email"] as? String
                    // Setup UI
                    delegate.setTitle(name ?? "")
                    // Setup user
                    AppDelegate.user = LocalUser(id: id, name: name ?? "", email: email)
                    
                    self.dismiss(animated: true, completion:nil)
                } else {
                    
                }
            }
        }
        
    }
}

// MARK: Google SignIn Delegate Method
extension LoginViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard let id = user.userID else {
            showAlertMessage(presenter: self, title: "Login with Google Failed", message: "Please try again", handler: nil, completion: nil)
            return
        }
        let name = user?.profile?.name
        let email = user?.profile?.email
        loginDelegate?.setTitle(name ?? "")
        AppDelegate.user = LocalUser(id: id, name: name ?? "", email: email)
        
        self.dismiss(animated: true, completion:nil)
    }
}

// MARK: Functions to setup dismissing keyboard when tapping outside of it
extension LoginViewController {
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
