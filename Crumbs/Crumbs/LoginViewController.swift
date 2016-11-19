//
//  LoginViewController.swift
//  Crumbs
//
//  Created by Alexander Mason on 11/19/16.
//  Copyright © 2016 NY3. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBAction func loginButton(_ sender: Any) {
        
    }
    
    @IBAction func createAccountButton(_ sender: Any) {
        
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    


    func handleSignIn() {
        
        guard let email = emailTextField.text, let password = passwordTextField.text else { return }
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            if error != nil {
                print("user couldn't sign in \(error)")
                return
            }
            //present next view controller
            print("user signed in")
        })
        
    }
    
    
}
