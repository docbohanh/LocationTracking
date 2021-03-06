//
//  SignUpViewController.swift
//  LocationTracking
//
//  Created by Nguyen Hai Dang on 6/18/17.
//  Copyright © 2017 Nguyen Hai Dang. All rights reserved.
//

import UIKit
import Firebase

class SignUpViewController: OriginalViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signUpButton.isExclusiveTouch = true
        signUpButton.customBorder(radius: 5,color: .clear)
        self.addLeftBarItem(imageName: "ic_close_popup",title: "")
        view.tappedDismissKeyboard()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //MARK: - Action
    
    @IBAction func tappedDismiss(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - IBAction
    @IBAction func tappedSignUp(_ sender: UIButton) {
        self.showHUD()
        
        if (emailTextField.text?.characters.count)! > 0 && (passwordTextField.text?.characters.count)! > 0 && (confirmPasswordTextField.text?.characters.count)! > 0 && (nameTextField.text?.characters.count)! > 0 && confirmPasswordTextField.text == passwordTextField.text {
            if (passwordTextField.text?.count)! < 6 {
                self.showAlert(title: "", message: "Password must be more than 6 characters", cancelTitle: "", okTitle: "OK", onOKAction: {_ in
                    
                })
                self.hideHUD()
                return
            }
            
            FIRAuth.auth()?.createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
                
                if error != nil {
                    self.view.makeToast((error?.localizedDescription)!, duration: 2.0, position: .center)
                    self.hideHUD()
                    return
                }
                
                //Create new user on firebase
                app_delegate.firebaseObject.registerNewAccount(email: self.emailTextField.text!, password: self.passwordTextField.text!,name: self.nameTextField.text!,  onCompletionHandler: {id in
                    //Create profile in databasee
                    DatabaseManager.updateProfile(id:id, email:self.emailTextField.text!, name: self.nameTextField.text!, latitude: 0, longitude: 0,onCompletionHandler: {_ in
                        //Present after updated profile
                        app_delegate.profile = DatabaseManager.getProfile()
                        self.dismiss(animated: false, completion: {_ in
                            let drawerController = app_delegate.initRevealViewController()
                            let visibleViewController: UIViewController = Common.getVisibleViewController(UIApplication.shared.keyWindow?.rootViewController)!
                            visibleViewController.present(drawerController, animated: true, completion: nil)
                            self.hideHUD()
                        })
                    })
                })
            }
        } else {
            self.hideHUD()
            view.makeToast("Please input email, username and password exactly", duration: 2.0, position: .center)
        }
    }
}
