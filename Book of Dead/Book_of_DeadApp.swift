//
//  Book_of_DeadApp.swift
//  Book of Dead
//
//  Created by Алкександр Степанов on 07.10.2025.
//

import SwiftUI

@main
struct Book_of_DeadApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

class AppDelegate: NSObject, URLSessionDelegate {
    @AppStorage("levelInfo") var level = false
    @AppStorage("valid") var validationIsOn = false
    static var orientationLock = UIInterfaceOrientationMask.all
    private var validationPerformed = false
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if OrientationManager.shared.isHorizontalLock {
            // Для игры - только вертикальная ориентация
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                AppDelegate().setOrientation(to: .portrait)
            }
            return .portrait
        } else {
            // Для сайта - все ориентации
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                AppDelegate.orientationLock = .allButUpsideDown
            }
            return .allButUpsideDown
        }
    }
}

extension AppDelegate: UIApplicationDelegate {
    
    func setOrientation(to orientation: UIInterfaceOrientation) {
        switch orientation {
        case .portrait:
            AppDelegate.orientationLock = .portrait
        case .landscapeRight:
            AppDelegate.orientationLock = .landscapeRight
        case .landscapeLeft:
            AppDelegate.orientationLock = .landscapeLeft
        case .portraitUpsideDown:
            AppDelegate.orientationLock = .portraitUpsideDown
        default:
            AppDelegate.orientationLock = .all
        }
        
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }
    
}
