//
//  AppDelegate.swift
//  Sample
//
//  Created by Leandro Zanol on 5/18/16.
//  Copyright © 2016 Samba Tech. All rights reserved.
//

import UIKit
import SambaPlayer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	static var externalIp: String = ""
	
	var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		loadExternalIp()
        SambaCast.sharedInstance.enableSDKLogging = true
        SambaCast.sharedInstance.config()
        
        SambaDownloadManager.sharedInstance.config(maximumDurationTimeForLicensesOfProtectedContentInMinutes: 28800)
        
		return true
	}
	
	private func loadExternalIp() {
		Helpers.requestURL("https://api.ipify.org") { (response: String?) in
			guard let response = response else { return }
			AppDelegate.externalIp = response
		}
	}
}
