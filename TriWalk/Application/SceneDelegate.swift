//
//  SceneDelegate.swift
//  TriWalk
//
//  Created by Sebin Kwon on 3/27/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        LocationManager.shared.requestAuthorization()
        window?.rootViewController = MainContainerViewController()
        window?.makeKeyAndVisible()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        checkLocationPermission()
    }
    
    private func checkLocationPermission() {
            let status = LocationManager.shared.authorizationStatus
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                // 권한이 허용된 경우 위치 요청 시작
                LocationManager.shared.requestLocation()
                // 알림이 필요하다면 NotificationCenter로 알림 전송
                NotificationCenterManager.locationPermissionGranted.post()
//                NotificationCenter.default.post(name: .locationPermissionGranted, object: nil)
            case .denied, .restricted:
                // 권한이 거부된 경우 권한 요청 알림 표시
                if let rootVC = window?.rootViewController {
                    let alertService = AlertService()
                    alertService.showSettingsAlert(
                        on: rootVC,
                        title: "위치 서비스 권한 필요",
                        message: "산책 기록을 위해 위치 권한이 필요합니다. 설정에서 권한을 허용해주세요."
                    )
                }
            default:
                break
            }
        }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    
}

