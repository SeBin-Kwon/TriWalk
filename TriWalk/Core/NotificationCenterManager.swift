//
//  NotificationCenterManager.swift
//  TriWalk
//
//  Created by Sebin Kwon on 4/9/25.
//

import UIKit
import Combine

protocol NotificationCenterHandler {
    var name: Notification.Name { get }
}

extension NotificationCenterHandler {
    func publisher() -> AnyPublisher<Any?, Never> {
        NotificationCenter.default
            .publisher(for: name)
            .map { $0.object }
            .eraseToAnyPublisher()
    }

    func post(object: Any? = nil) {
        NotificationCenter.default.post(name: name, object: object, userInfo: nil)
    }
}

enum NotificationCenterManager: NotificationCenterHandler {
    case didEnterBackground
    case willEnterForeground
    case locationPermissionGranted
    case locationPermissionChanged
    case motionPermissionGranted
    case motionPermissionChanged
    case backgroundLocationChanged
    case walkRecordDeleted

    var name: Notification.Name {
        switch self {
        case .didEnterBackground:
            return UIApplication.didEnterBackgroundNotification
        case .willEnterForeground:
            return UIApplication.willEnterForegroundNotification
        case .locationPermissionGranted:
            return Notification.Name("LocationPermissionGranted")
        case .locationPermissionChanged:
            return Notification.Name("LocationPermissionChanged")
        case .motionPermissionGranted:
            return Notification.Name("motionPermissionGranted")
        case .motionPermissionChanged:
            return Notification.Name("motionPermissionChanged")
        case .backgroundLocationChanged:
            return Notification.Name("backgroundLocationChanged")
        case .walkRecordDeleted:
            return Notification.Name("walkRecordDeleted")
        }
    }
}

