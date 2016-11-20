//
//  AppDelegate.swift
//  Crumbs
//
//  Created by Forrest Zhao on 11/19/16.
//  Copyright © 2016 NY3. All rights reserved.
//

import UIKit
import Firebase
import SwiftGifOrigin

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var customizedLaunchScreenView: UIView?
    
    override init() {
        super.init()
        FIRApp.configure()

    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Override point for customization after application launch.
        //application.statusBarHidden = true
        application.setStatusBarHidden(true, with: .none)
        // customized launch screen
        if let window = self.window {
            self.customizedLaunchScreenView = UIView(frame: window.bounds)
            self.customizedLaunchScreenView?.backgroundColor = UIColor.green
            
            self.window?.makeKeyAndVisible()
            let myGif = UIImage.gif(name: "crumb")
            let gifView = UIImageView(frame: CGRect(x: window.center.x, y: window.center.y, width: 300, height: 300))
            gifView.image = myGif
            customizedLaunchScreenView?.addSubview(gifView)
            self.window?.addSubview(self.customizedLaunchScreenView!)
            self.window?.bringSubview(toFront: self.customizedLaunchScreenView!)
            UIView.animate(withDuration: 1, delay: 2, options: .curveEaseOut,
                                       animations: { () -> Void in
                                        self.customizedLaunchScreenView?.alpha = 0 },
                                       completion: { _ in
                                        self.customizedLaunchScreenView?.removeFromSuperview() })
        }
        
        if FIRAuth.auth()?.currentUser?.uid == nil {
            //present login view controller
        }  else {
            _ = FIRAuth.auth()?.currentUser?.uid
            //present landing page view controller
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

